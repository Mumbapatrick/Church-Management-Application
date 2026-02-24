import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MembershipRequestScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  _MembershipRequestScreenState createState() => _MembershipRequestScreenState();
}

class _MembershipRequestScreenState extends State<MembershipRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String gender = "";
  String maritalStatus = "";
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() &&
        gender.isNotEmpty &&
        maritalStatus.isNotEmpty) {

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
          'gender': gender,
          'maritalStatus': maritalStatus,
          'occupation': _occupationController.text.trim().isEmpty
              ? null
              : _occupationController.text.trim(),
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Membership request submitted successfully')),
        );

        _formKey.currentState!.reset();
        setState(() {
          gender = "";
          maritalStatus = "";
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

      setState(() {
        _isLoading = false;
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
    }
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _dobController.text = "${date.year}-${date.month}-${date.day}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Membership Request"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) =>
                value == null || value.isEmpty
                    ? "Please enter your name"
                    : null,
              ),

              const SizedBox(height: 12),

              //PHONE NUMBER (RESTRICTED)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "07XXXXXXXX",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter phone number";
                  }

                  if (!RegExp(r'^07\d{8}$').hasMatch(value)) {
                    return "Enter valid Kenyan number (07XXXXXXXX)";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (value) =>
                value == null || value.isEmpty
                    ? "Please enter your location"
                    : null,
              ),

              const SizedBox(height: 12),

              // Email (Optional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Email Address (Optional)"),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 12),

              // Date of Birth
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration:
                const InputDecoration(labelText: "Date of Birth"),
                onTap: _pickDate,
              ),

              const SizedBox(height: 12),

              // Gender
              DropdownButtonFormField<String>(
                value: gender.isEmpty ? null : gender,
                items: ["Male", "Female", "Other"]
                    .map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g),
                ))
                    .toList(),
                decoration:
                const InputDecoration(labelText: "Gender"),
                validator: (value) =>
                value == null || value.isEmpty
                    ? "Please select gender"
                    : null,
                onChanged: (val) =>
                    setState(() => gender = val ?? ""),
              ),

              const SizedBox(height: 12),

              // Marital Status
              DropdownButtonFormField<String>(
                value: maritalStatus.isEmpty ? null : maritalStatus,
                items: ["Single", "Married", "Divorced", "Widowed"]
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                ))
                    .toList(),
                decoration:
                const InputDecoration(
                    labelText: "Marital Status"),
                validator: (value) =>
                value == null || value.isEmpty
                    ? "Please select marital status"
                    : null,
                onChanged: (val) =>
                    setState(() => maritalStatus = val ?? ""),
              ),

              const SizedBox(height: 12),

              // Occupation (Optional)
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                    labelText: "Occupation (Optional)"),
              ),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitRequest,
                child: const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
