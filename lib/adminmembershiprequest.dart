import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================
// COLORS — MATCHED TO DASHBOARD & APPOINTMENTS
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color gold = Color(0xFFFFD700);

// ============================================================
// ADMIN MEMBERSHIP REQUESTS PAGE
// ============================================================

class AdminMembershipRequests extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminMembershipRequests({super.key, this.onBack});

  @override
  State<AdminMembershipRequests> createState() =>
      _AdminMembershipRequestsState();
}

class _AdminMembershipRequestsState extends State<AdminMembershipRequests> {
  final CollectionReference _requestsRef =
  FirebaseFirestore.instance.collection('membership_requests');

  final CollectionReference _membersRef =
  FirebaseFirestore.instance.collection('members');

  final List<String> departments = [
    'Youth Ministry',
    'Worship Team',
    'Children Ministry',
    'Administration',
    'Choir',
    'Outreach',
    'Ushering',
    'Media Team',
    'Prayer Team',
    'Counseling'
  ];

  final List<String> roles = [
    'Member',
    'Admin',
  ];

  Map<String, String> selectedDepartments = {};
  Map<String, String> selectedRoles = {};

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red.shade700 : purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _approveRequest(String docId, Map<String, dynamic> requestData,
      String department, String role) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final approverName =
          currentUser?.displayName ?? currentUser?.email ?? "Admin";

      await _membersRef.add({
        'name': requestData['name'],
        'email': requestData['email'],
        'phone': requestData['phone'],
        'location': requestData['location'],
        'department': department,
        'role': role,
        'approvedBy': approverName,
        'status': 'approved',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _requestsRef.doc(docId).delete();

      if (mounted) {
        _showSnackBar("Request approved and moved to Members");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error approving request: $e", isError: true);
      }
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await _requestsRef.doc(docId).update({'status': newStatus});
      if (mounted) {
        _showSnackBar("Request marked as $newStatus");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error updating status: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4C087A),
              Color(0xFF6A0DAD),
              Color(0xFF8B5CF6),
              Color(0xFFFFD700),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _requestsRef
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final requests = snapshot.data!.docs;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1000
                            ? 3
                            : (constraints.maxWidth >= 650 ? 2 : 1);

                        if (columns == 1) {
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final doc = requests[index];
                              final data =
                              doc.data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildRequestCard(doc.id, data),
                              );
                            },
                          );
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1250),
                            child: GridView.builder(
                              padding:
                              const EdgeInsets.fromLTRB(20, 10, 20, 35),
                              itemCount: requests.length,
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 470,
                              ),
                              itemBuilder: (context, index) {
                                final doc = requests[index];
                                final data =
                                doc.data() as Map<String, dynamic>;
                                return _buildRequestCard(doc.id, data);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR WITH BACK ARROW
  // ==========================================================

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Row(
            children: [
              if (widget.onBack != null) ...[
                _TopBarButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: widget.onBack!,
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Requests',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Review, assign roles, and approve new members',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DESIGN
  // ==========================================================

  Widget _buildRequestCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unnamed Applicant';
    final email = data['email'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final location = data['location'] ?? 'N/A';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();

    List<Color> headerColors;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        headerColors = const [Color(0xFF0F766E), Color(0xFF2DD4BF)];
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        headerColors = const [Color(0xFFDC2626), Color(0xFFF87171)];
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        headerColors = const [purple, purpleLight];
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            height: 85,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: headerColors.first,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.email_rounded,
                    title: 'Email',
                    value: email,
                    color: headerColors.first,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    title: 'Phone',
                    value: phone,
                    color: headerColors.first,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                    value: location,
                    color: headerColors.first,
                  ),

                  if (status == 'pending') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),

                    // Department Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDepartments[docId],
                      hint: const Text(
                        "Select Department",
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        fillColor: const Color(0xFFF8F5FA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF202124)),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartments[docId] = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedRoles[docId],
                      hint: const Text(
                        "Select Role",
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        fillColor: const Color(0xFFF8F5FA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF202124)),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRoles[docId] = value!;
                        });
                      },
                    ),

                    const Spacer(),

                    // Action Buttons (Line-free)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              "Approve",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            onPressed: () {
                              if (selectedDepartments[docId] == null ||
                                  selectedRoles[docId] == null) {
                                _showSnackBar(
                                    "Select a department and role first",
                                    isError: true);
                                return;
                              }
                              _approveRequest(
                                docId,
                                data,
                                selectedDepartments[docId]!,
                                selectedRoles[docId]!,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text(
                              "Reject",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            onPressed: () => _updateStatus(docId, 'rejected'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY & ERROR STATES
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: purple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_rounded,
                size: 34,
                color: purple,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No Requests Found',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no pending membership requests right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPER COMPONENTS
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}