import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/member.dart' as model;

class MemberDirectory extends StatefulWidget {
  final VoidCallback onBack;
  final Function(model.Member) onSelectMember;

  const MemberDirectory({
    super.key,
    required this.onBack,
    required this.onSelectMember,
  });

  @override
  State<MemberDirectory> createState() => _MemberDirectoryState();
}

class _MemberDirectoryState extends State<MemberDirectory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String searchTerm = '';
  String selectedDepartment = 'all';
  bool _isSearchFocused = false;

  List<model.Member> membersList = [];
  bool isLoading = true;

  // 🔹 Sacred Theme Color Palette
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color lightPurpleAccent = Color(0xFFA78BFA);
  static const Color deepBgGradientStart = Color(0xFF2E1065);
  static const Color deepBgGradientEnd = Color(0xFF4C1D95);

  // ⚜️ Warm Alabaster & Sacred Gold Palette for Cards
  static const Color cardBgStart = Color(0xFFFFFDF8);
  static const Color cardBgEnd = Color(0xFFFAF5E8);
  static const Color sacredGold = Color(0xFFD97706);
  static const Color sacredGoldLight = Color(0xFFFBBF24);
  static const Color sacredGoldDark = Color(0xFFB45309);

  final List<String> departmentsList = [
    'all',
    'Youth Ministry',
    'Worship Team',
    'Children Ministry',
    'Administration',
    'Choir',
    'Outreach',
    'Ushering',
    'Media Team',
    'Prayer Team',
    'Counseling',
    'Unassigned'
  ];

  @override
  void initState() {
    super.initState();
    _listenToAllMembers();
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

  void _listenToAllMembers() async {
    _firestore.collection('members').snapshots().listen((membersSnap) async {
      List<model.Member> members = membersSnap.docs
          .map((doc) => model.Member.fromMap(doc.id, doc.data()))
          .toList();

      final requestsSnap = await _firestore
          .collection('membership_requests')
          .where('status', isEqualTo: 'approved')
          .get();

      List<model.Member> approved = requestsSnap.docs
          .map((doc) => model.Member.fromMap(doc.id, doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          membersList = [...members, ...approved];
          isLoading = false;
        });
      }
    });
  }

  // 🔍 Centered Sacred Alabaster & Gold Details Modal
  void _showMemberDetailsModal(model.Member member) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Member Details',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cardBgStart, cardBgEnd],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: sacredGold.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sacredGold.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            sacredGoldLight,
                            primaryPurple,
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF3B0764),
                        child: Text(
                          member.name
                              .trim()
                              .split(' ')
                              .map((n) => n.isNotEmpty ? n[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: cardBgStart,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      member.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF311242),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryPurple.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        member.department.isEmpty
                            ? "Unassigned"
                            : member.department,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          color: primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(color: sacredGold.withOpacity(0.25)),
                    const SizedBox(height: 12),
                    _buildModalInfoRow(
                        Icons.email_outlined, "Email", member.email),
                    const SizedBox(height: 12),
                    _buildModalInfoRow(
                        Icons.phone_outlined, "Phone", member.phone),
                    const SizedBox(height: 12),
                    _buildModalInfoRow(
                      Icons.location_on_outlined,
                      "Location",
                      member.location.isEmpty ? 'N/A' : member.location,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          elevation: 4,
                          shadowColor: primaryPurple.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSelectMember(member);
                        },
                        child: const Text(
                          "SELECT MEMBER",
                          style: TextStyle(
                            fontFamily: 'serif',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
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

  Widget _buildModalInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sacredGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: sacredGoldDark),
        ),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: TextStyle(
            fontFamily: 'serif',
            color: const Color(0xFF581C87).withOpacity(0.7),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E1B4B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = membersList.where((member) {
      final matchesSearch = member.name
          .toLowerCase()
          .contains(searchTerm.toLowerCase()) ||
          member.email.toLowerCase().contains(searchTerm.toLowerCase()) ||
          member.phone.contains(searchTerm) ||
          member.location.toLowerCase().contains(searchTerm.toLowerCase());

      final dept =
      member.department.isEmpty ? 'Unassigned' : member.department;
      final matchesDepartment =
          selectedDepartment == 'all' || dept == selectedDepartment;

      return matchesSearch && matchesDepartment;
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: deepBgGradientStart,
      appBar: AppBar(
        title: const Text(
          "MEMBERS DIRECTORY",
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            color: cardBgStart,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cardBgStart),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deepBgGradientStart,
              deepBgGradientEnd,
              Color(0xFF1E1B4B),
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
              child: CircularProgressIndicator(color: sacredGoldLight))
              : Column(
            children: [
              // 🔎 Floating Glassmorphic Top Search & Department Filter Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sacredGold.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _isSearchFocused
                              ? primaryPurple.withOpacity(0.25)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isSearchFocused
                                ? sacredGoldLight
                                : Colors.transparent,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            color: cardBgStart,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isSearchFocused
                                  ? sacredGoldLight
                                  : Colors.white.withOpacity(0.5),
                            ),
                            hintText: "Search directory...",
                            hintStyle: TextStyle(
                              fontFamily: 'serif',
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => searchTerm = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sacredGold.withOpacity(0.25),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDepartment,
                          dropdownColor: const Color(0xFF1E1B4B),
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: sacredGoldLight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          items: departmentsList
                              .map((dept) => DropdownMenuItem(
                            value: dept,
                            child: Text(
                              dept == 'all' ? 'All' : dept,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cardBgStart,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedDepartment = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🧑 Sacred Alabaster & Gold Member Cards List
              Expanded(
                child: filteredMembers.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 48,
                        color: sacredGold.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No members found matching criteria.",
                        style: TextStyle(
                          fontFamily: 'serif',
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];

                    return CenteredAnimatedCard(
                      index: index,
                      child: Container(
                        margin:
                        const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [cardBgStart, cardBgEnd],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: sacredGold.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: sacredGold.withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(22),
                            onTap: () =>
                                _showMemberDetailsModal(member),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // Avatar with glowing Gold/Purple Ring
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: sacredGold
                                              .withOpacity(0.3),
                                          blurRadius: 10,
                                          offset:
                                          const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                      const Color(0xFF311242),
                                      child: Text(
                                        member.name
                                            .trim()
                                            .split(' ')
                                            .map((n) => n.isNotEmpty
                                            ? n[0]
                                            : '')
                                            .take(2)
                                            .join()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'serif',
                                          color: sacredGoldLight,
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                member.name,
                                                style: const TextStyle(
                                                  fontFamily: 'serif',
                                                  fontSize: 17,
                                                  fontWeight:
                                                  FontWeight
                                                      .bold,
                                                  color: Color(
                                                      0xFF2A0A3B),
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 🔹 Role badge moved to the right
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: member.role.toLowerCase() == "admin"
                                                    ? sacredGold.withOpacity(0.18)
                                                    : primaryPurple.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: member.role.toLowerCase() == "admin"
                                                      ? sacredGold
                                                      : primaryPurple.withOpacity(0.4),
                                                ),
                                              ),
                                              child: Text(
                                                member.role.toUpperCase(),
                                                style: TextStyle(
                                                  fontFamily: 'serif',
                                                  color: member.role.toLowerCase() == "admin"
                                                      ? sacredGoldDark
                                                      : primaryPurple,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryPurple
                                                .withOpacity(0.08),
                                            borderRadius:
                                            BorderRadius.circular(
                                                8),
                                          ),
                                          child: Text(
                                            member.department.isEmpty
                                                ? "Unassigned"
                                                : member.department,
                                            style: const TextStyle(
                                              fontFamily: 'serif',
                                              color: primaryPurple,
                                              fontWeight:
                                              FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Info Rows
                                        _buildInfoRow(
                                          Icons.location_on_outlined,
                                          member.location.isEmpty
                                              ? 'N/A'
                                              : member.location,
                                        ),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(
                                          Icons.email_outlined,
                                          member.email,
                                        ),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(
                                          Icons.phone_outlined,
                                          member.phone,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 📊 Bottom Summary Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border(
                    top: BorderSide(
                      color: sacredGold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  "Showing ${filteredMembers.length} of ${membersList.length} members",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: cardBgStart.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: sacredGoldDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4C1D95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CENTER-ANIMATED CARD WRAPPER (SCALE + FADE)
// ============================================================

class CenteredAnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;

  const CenteredAnimatedCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<CenteredAnimatedCard> createState() => _CenteredAnimatedCardState();
}

class _CenteredAnimatedCardState extends State<CenteredAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}