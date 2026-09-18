import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color purplePrimary = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color inputBg = Color(0xFFF8F9FA);
const Color textDark = Color(0xFF1E293B);
const Color textGrey = Color(0xFF64748B);

class MembershipRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MembershipRequestScreen({Key? key, required this.onBack})
      : super(key: key);

  @override
  State<MembershipRequestScreen> createState() =>
      _MembershipRequestScreenState();
}

class _MembershipRequestScreenState extends State<MembershipRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _gender;
  String? _maritalStatus;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() &&
        _gender != null &&
        _maritalStatus != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('membership_requests').add({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
          'gender': _gender,
          'maritalStatus': _maritalStatus,
          'occupation': _occupationController.text.trim().isEmpty
              ? null
              : _occupationController.text.trim(),
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membership request submitted successfully'),
            backgroundColor: purplePrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _formKey.currentState!.reset();
        _nameController.clear();
        _phoneController.clear();
        _locationController.clear();
        _emailController.clear();
        _dobController.clear();
        _occupationController.clear();

        setState(() {
          _gender = null;
          _maritalStatus = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: purplePrimary,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: Transform.scale(
            scale: 0.85,
            child: child!,
          ),
        );
      },
    );

    if (date != null) {
      setState(() {
        _dobController.text =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      });
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
            colors: [purpleDark, purplePrimary, purpleLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCardHeader(),
                            const SizedBox(height: 24),

                            // Full Name
                            _buildFieldLabel("Full Name", isRequired: true),
                            _buildTextField(
                              controller: _nameController,
                              hintText: "John Doe",
                              icon: Icons.person_outline_rounded,
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Please enter your name"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            // Phone Number
                            _buildFieldLabel("Phone Number", isRequired: true),
                            _buildTextField(
                              controller: _phoneController,
                              hintText: "07XXXXXXXX / 01XXXXXXXX",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Please enter phone number"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            // Location
                            _buildFieldLabel("Location", isRequired: true),
                            _buildTextField(
                              controller: _locationController,
                              hintText: "City, Estate, or Neighborhood",
                              icon: Icons.location_on_outlined,
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Please enter your location"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            // Email Address
                            _buildFieldLabel("Email Address (Optional)"),
                            _buildTextField(
                              controller: _emailController,
                              hintText: "example@email.com",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),

                            // Date of Birth
                            _buildFieldLabel("Date of Birth", isRequired: true),
                            _buildTextField(
                              controller: _dobController,
                              hintText: "YYYY-MM-DD",
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                              onTap: _pickDate,
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Please select date of birth"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            // Gender
                            _buildFieldLabel("Gender", isRequired: true),
                            _buildDropdownField(
                              value: _gender,
                              hintText: "Select Gender",
                              icon: Icons.wc_rounded,
                              items: _genders,
                              onChanged: (val) =>
                                  setState(() => _gender = val),
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Please select gender"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            // Marital Status
                            _buildFieldLabel("Marital Status", isRequired: true),
                            _buildDropdownField(
                              value: _maritalStatus,
                              hintText: "Select Marital Status",
                              icon: Icons.people_outline_rounded,
                              items: _maritalStatuses,
                              onChanged: (val) =>
                                  setState(() => _maritalStatus = val),
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Please select marital status"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            // Occupation
                            _buildFieldLabel("Occupation (Optional)"),
                            _buildTextField(
                              controller: _occupationController,
                              hintText: "e.g., Software Developer, Teacher",
                              icon: Icons.work_outline_rounded,
                            ),
                            const SizedBox(height: 28),

                            // Submit Button / Loading Indicator
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purplePrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Submit Request",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: purplePrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Membership Request",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Join our church family and stay connected",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: purplePrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.assignment_ind_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Member Information",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            Text(
              "Please complete all required fields below.",
              style: TextStyle(
                fontSize: 12,
                color: textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: textGrey.withOpacity(0.6),
        ),
        prefixIcon: Icon(icon, color: purplePrimary, size: 20),
        filled: true,
        fillColor: inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: purplePrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: textGrey,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: textGrey.withOpacity(0.6),
        ),
        prefixIcon: Icon(icon, color: purplePrimary, size: 20),
        filled: true,
        fillColor: inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: purplePrimary, width: 1.5),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}