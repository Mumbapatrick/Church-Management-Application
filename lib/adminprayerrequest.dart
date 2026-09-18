import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// DESIGN CONSTANTS & PALETTE
// ============================================================

const Color purpleDark = Color(0xFF2E004F);
const Color purplePrimary = Color(0xFF6B21A8);
const Color purpleLight = Color(0xFFA855F7);
const Color purpleAccent = Color(0xFFE9D5FF);
const Color goldAccent = Color(0xFFFACC15);

class PrayerCategory {
  final String value;
  final String label;
  final IconData icon;
  final List<Color> colors;

  const PrayerCategory({
    required this.value,
    required this.label,
    required this.icon,
    required this.colors,
  });
}

// ============================================================
// MODEL
// ============================================================

class PrayerRequest {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String title;
  final String description;
  final bool isAnonymous;
  final bool isUrgent;
  final String dateSubmitted;
  final String status;

  const PrayerRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.title,
    required this.description,
    required this.isAnonymous,
    required this.isUrgent,
    required this.dateSubmitted,
    required this.status,
  });

  factory PrayerRequest.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    final Map<String, dynamic> data =
    rawData is Map<String, dynamic> ? rawData : {};

    return PrayerRequest(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Anonymous',
      category: data['category']?.toString() ?? 'personal',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      isAnonymous: data['isAnonymous'] == true,
      isUrgent: data['isUrgent'] == true,
      dateSubmitted: data['dateSubmitted']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
    );
  }
}

// ============================================================
// ADMIN PRAYER REQUESTS PAGE
// ============================================================

class AdminPrayerRequests extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminPrayerRequests({
    super.key,
    this.onBack,
  });

  @override
  State<AdminPrayerRequests> createState() => _AdminPrayerRequestsState();
}

class _AdminPrayerRequestsState extends State<AdminPrayerRequests> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _isSearchFocused = false;

  static const List<PrayerCategory> _categories = [
    PrayerCategory(
      value: 'personal',
      label: 'Personal',
      icon: Icons.person_rounded,
      colors: [purplePrimary, purpleLight],
    ),
    PrayerCategory(
      value: 'family',
      label: 'Family',
      icon: Icons.family_restroom_rounded,
      colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    ),
    PrayerCategory(
      value: 'healing',
      label: 'Healing',
      icon: Icons.favorite_rounded,
      colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
    ),
    PrayerCategory(
      value: 'ministry',
      label: 'Ministry',
      icon: Icons.church_rounded,
      colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await _firestore
          .collection('prayer_requests')
          .doc(docId)
          .update({'status': newStatus});
      _showSnackBar('Status updated to ${newStatus.toUpperCase()}');
    } catch (e) {
      _showSnackBar('Failed to update status: $e', isError: true);
    }
  }

  Future<void> _deleteRequest(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Prayer Request',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this prayer request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('prayer_requests').doc(docId).delete();
        _showSnackBar('Prayer request deleted successfully');
      } catch (e) {
        _showSnackBar('Failed to delete request: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade600 : purplePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Centered Animated Modal Dialog for Details
  void _showDetailsModal(PrayerRequest request) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Prayer Details',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          request.isAnonymous
                              ? Icons.visibility_off_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          request.isAnonymous
                              ? 'Anonymous'
                              : '${request.name} (ID: ${request.userId.isEmpty ? "N/A" : request.userId.substring(0, 5)}...)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      request.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE11D48)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteRequest(request.id);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFE11D48)),
                            label: Text(
                              'Delete',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFE11D48),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6FC),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildBackground()),
              Column(
                children: [
                  _buildHeader(),
                  _buildAnimatedSearchBar(),
                  Expanded(child: _buildRequestsList()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E004F),
            Color(0xFF4A1278),
            Color(0xFF6B21A8),
            Color(0xFFF3E8FF),
            Color(0xFFF8F6FC),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.18, 0.38, 0.70, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back Navigation Arrow Button
          InkWell(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin - Prayer Requests',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Manage and moderate intercession requests',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: _isSearchFocused ? 12 : 20,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isSearchFocused ? 24 : 18),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused
                ? purplePrimary.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: _isSearchFocused ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search title, content, or user...',
              prefixIcon: const Icon(Icons.search_rounded, color: purplePrimary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const Divider(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'pending', 'praying', 'answered'].map((status) {
                final selected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      label: Text(status.toUpperCase()),
                      selected: selected,
                      selectedColor: purplePrimary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) =>
                          setState(() => _filterStatus = status),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prayer_requests')
          .orderBy('dateSubmitted', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading requests'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: purplePrimary));
        }

        final docs = snapshot.data?.docs ?? [];
        final requests = docs
            .map((doc) => PrayerRequest.fromFirestore(doc))
            .where((req) {
          final matchesStatus = _filterStatus == 'all' ||
              req.status.toLowerCase() == _filterStatus;
          final matchesSearch = req.title.toLowerCase().contains(_searchQuery) ||
              req.description.toLowerCase().contains(_searchQuery) ||
              req.name.toLowerCase().contains(_searchQuery);
          return matchesStatus && matchesSearch;
        }).toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No requests found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return AnimatedCardWrapper(
              index: index,
              child: _buildAdminCard(request),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminCard(PrayerRequest request) {
    final category = _categories.firstWhere(
          (cat) => cat.value.toLowerCase() == request.category.toLowerCase(),
      orElse: () => _categories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                avatar: Icon(category.icon, size: 14, color: Colors.white),
                label: Text(category.label,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: category.colors.first,
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (val) => _updateStatus(request.id, val),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'pending', child: Text('Mark Pending')),
                  const PopupMenuItem(
                      value: 'praying', child: Text('Mark Praying')),
                  const PopupMenuItem(
                      value: 'answered', child: Text('Mark Answered')),
                ],
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: purpleAccent.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        request.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: purpleDark,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By: ${request.isAnonymous ? "Anonymous" : request.name}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: purplePrimary.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showDetailsModal(request),
                child: Text(
                  'View Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: purplePrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANIMATED CARD WRAPPER (STAGGERED SLIDE & FADE)
// ============================================================

class AnimatedCardWrapper extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedCardWrapper({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedCardWrapper> createState() => _AnimatedCardWrapperState();
}

class _AnimatedCardWrapperState extends State<AnimatedCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}