import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'model/member.dart';

enum MemberFormMode { add, request }

class MemberListScreen extends StatelessWidget {
  const MemberListScreen({super.key});

  // 🔹 Purple & Sacred Gold Palette Constants
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color lightPurpleAccent = Color(0xFFA78BFA);
  static const Color deepBgGradientStart = Color(0xFF2E1065);
  static const Color deepBgGradientEnd = Color(0xFF4C1D95);

  static const Color cardBgStart = Color(0xFFFFFDF8);
  static const Color cardBgEnd = Color(0xFFFAF5E8);
  static const Color sacredGold = Color(0xFFD97706);
  static const Color sacredGoldLight = Color(0xFFFBBF24);

  void _navigateToAddMember(BuildContext context, MemberFormMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(
          mode: mode,
          onBack: () => Navigator.pop(context),
          onSave: (member) {
            if (mode == MemberFormMode.add) {
              FirebaseFirestore.instance
                  .collection('members')
                  .add(member.toMap());
            } else {
              FirebaseFirestore.instance
                  .collection('membership_requests')
                  .add(member.toMap());
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'MEMBERSHIP MANAGEMENT',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            color: cardBgStart,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Graphic
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: sacredGold.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: sacredGold.withOpacity(0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      size: 56,
                      color: sacredGoldLight,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Admin Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sacredGold,
                        foregroundColor: cardBgStart,
                        elevation: 6,
                        shadowColor: sacredGold.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.person_add, color: cardBgStart),
                      label: const Text(
                        'ADD MEMBER (ADMIN)',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      onPressed: () =>
                          _navigateToAddMember(context, MemberFormMode.add),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Request Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cardBgStart,
                        side: BorderSide(
                          color: sacredGoldLight.withOpacity(0.6),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.06),
                      ),
                      icon: const Icon(Icons.request_page,
                          color: sacredGoldLight),
                      label: const Text(
                        'REQUEST MEMBERSHIP (USER)',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      onPressed: () => _navigateToAddMember(
                          context, MemberFormMode.request),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddMemberScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(Member) onSave;
  final MemberFormMode mode;

  const AddMemberScreen({
    super.key,
    required this.onBack,
    required this.onSave,
    required this.mode,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();

  String department = '';
  String role = 'member';
  String gender = '';
  String maritalStatus = '';
  String dateOfBirth = '';

  // 🔹 Color Theme Tokens
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color lightPurpleAccent = Color(0xFFA78BFA);
  static const Color deepBgGradientStart = Color(0xFF2E1065);
  static const Color deepBgGradientEnd = Color(0xFF4C1D95);

  static const Color cardBgStart = Color(0xFFFFFDF8);
  static const Color cardBgEnd = Color(0xFFFAF5E8);
  static const Color sacredGold = Color(0xFFD97706);
  static const Color sacredGoldLight = Color(0xFFFBBF24);
  static const Color sacredGoldDark = Color(0xFFB45309);

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

  final List<String> roles = ['member', 'admin'];
  final List<String> genders = ['Male', 'Female'];
  final List<String> maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate() &&
        (widget.mode == MemberFormMode.request || department.isNotEmpty)) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final addedByName =
          currentUser?.displayName ?? currentUser?.email ?? 'Unknown';

      final member = Member(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        department: department,
        role: role,
        location: _locationController.text,
        dateOfBirth: dateOfBirth,
        gender: gender,
        maritalStatus: maritalStatus,
        occupation: _occupationController.text,
        addedBy: addedByName,
      );

      widget.onSave(member);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1B4B),
          content: Text(
            widget.mode == MemberFormMode.add
                ? '✅ Member registered successfully!'
                : '✅ Membership request sent!',
            style: const TextStyle(
              fontFamily: 'serif',
              color: cardBgStart,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      widget.onBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            '⚠️ Please fill in all required fields',
            style: TextStyle(
              fontFamily: 'serif',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  // 🏛️ Reusable Modern Input Field Style
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'serif',
        color: sacredGoldDark.withOpacity(0.85),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: sacredGoldDark, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: sacredGold.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryPurple,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.mode == MemberFormMode.add;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: deepBgGradientStart,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cardBgStart),
          onPressed: widget.onBack,
        ),
        title: Text(
          isAdmin ? 'ADD NEW MEMBER' : 'MEMBERSHIP REQUEST',
          style: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            color: cardBgStart,
            letterSpacing: 1.2,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cardBgStart, cardBgEnd],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: sacredGold.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: sacredGold.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Subtitle
                    Text(
                      isAdmin
                          ? "Enter member details below to register into the system database."
                          : "Fill in your profile details to submit a membership request.",
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: const Color(0xFF311242).withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration:
                      _buildInputDecoration('Full Name *', Icons.person_outline),
                      validator: (value) =>
                      value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration:
                      _buildInputDecoration('Email *', Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final emailRegex =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration:
                      _buildInputDecoration('Phone *', Icons.phone_outlined),
                      validator: (value) =>
                      value!.length < 10 ? 'Enter valid phone number' : null,
                    ),
                    const SizedBox(height: 16),

                    // Department (Admin only)
                    if (isAdmin) ...[
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBgStart,
                        decoration: _buildInputDecoration(
                            'Department *', Icons.church_outlined),
                        value: department.isNotEmpty ? department : null,
                        items: departments
                            .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => department = val!),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Role (Admin only)
                    if (isAdmin) ...[
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBgStart,
                        decoration: _buildInputDecoration(
                            'System Role', Icons.admin_panel_settings_outlined),
                        value: role,
                        items: roles
                            .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'serif',
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => role = val!),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _buildInputDecoration(
                          'Location', Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 16),

                    // Occupation
                    TextFormField(
                      controller: _occupationController,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration:
                      _buildInputDecoration('Occupation', Icons.work_outline),
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    DropdownButtonFormField<String>(
                      dropdownColor: cardBgStart,
                      decoration:
                      _buildInputDecoration('Gender', Icons.wc_outlined),
                      value: gender.isNotEmpty ? gender : null,
                      items: genders
                          .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          g,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => gender = val!),
                    ),
                    const SizedBox(height: 16),

                    // Marital Status
                    DropdownButtonFormField<String>(
                      dropdownColor: cardBgStart,
                      decoration: _buildInputDecoration(
                          'Marital Status', Icons.favorite_border),
                      value: maritalStatus.isNotEmpty ? maritalStatus : null,
                      items: maritalStatuses
                          .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => maritalStatus = val!),
                    ),
                    const SizedBox(height: 28),

                    // Form Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: primaryPurple.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: Text(
                              isAdmin ? 'REGISTER' : 'SEND REQUEST',
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: _handleSave,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4C1D95),
                              side: BorderSide(
                                color: primaryPurple.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: widget.onBack,
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 13,
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
        ),
      ),
    );
  }
}