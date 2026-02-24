import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'model/member.dart';

enum MemberFormMode { add, request } // Admin add vs user request

class MemberListScreen extends StatelessWidget {
  const MemberListScreen({super.key});

  void _navigateToAddMember(BuildContext context, MemberFormMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(
          mode: mode,
          onBack: () => Navigator.pop(context),
          onSave: (member) {
            if (mode == MemberFormMode.add) {
              // Admin adds member
              FirebaseFirestore.instance
                  .collection('members')
                  .add(member.toMap());
            } else {
              // User membership request
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
      appBar: AppBar(title: const Text('Members')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member (Admin)'),
              onPressed: () => _navigateToAddMember(context, MemberFormMode.add),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.request_page),
              label: const Text('Request Membership (User)'),
              onPressed: () =>
                  _navigateToAddMember(context, MemberFormMode.request),
            ),
          ],
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
  final List<String> maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];

  void _handleSave() async {
    if (_formKey.currentState!.validate() &&
        (widget.mode == MemberFormMode.request || department.isNotEmpty)) {

      // Get current user info
      final currentUser = FirebaseAuth.instance.currentUser;
      final addedByName = currentUser?.displayName ?? currentUser?.email ?? 'Unknown';

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
        addedBy: addedByName, // ✅ Automatically track who added
      );

      widget.onSave(member);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mode == MemberFormMode.add
                ? '✅ Member registered successfully!'
                : '✅ Membership request sent!',
          ),
        ),
      );

      widget.onBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill in all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.mode == MemberFormMode.add;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(isAdmin ? 'Add New Member' : 'Membership Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(value)) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone *'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.length < 10 ? 'Enter valid phone' : null,
              ),
              const SizedBox(height: 16),

              // Department (Admin only)
              if (isAdmin) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Department *'),
                  value: department.isNotEmpty ? department : null,
                  items: departments
                      .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                      .toList(),
                  onChanged: (val) => setState(() => department = val!),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Role (Admin only)
              if (isAdmin) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role'),
                  value: role,
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => role = val!),
                ),
                const SizedBox(height: 16),
              ],

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 16),

              // Occupation
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Occupation'),
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gender'),
                value: gender.isNotEmpty ? gender : null,
                items: genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val!),
              ),
              const SizedBox(height: 16),

              // Marital Status
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Marital Status'),
                value: maritalStatus.isNotEmpty ? maritalStatus : null,
                items: maritalStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => maritalStatus = val!),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(isAdmin ? 'Register Member' : 'Send Request'),
                      onPressed: _handleSave,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      child: const Text('Cancel'),
                      onPressed: widget.onBack,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
