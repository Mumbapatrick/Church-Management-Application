import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMembershipRequests extends StatefulWidget {
  final VoidCallback onBack;

  const AdminMembershipRequests({Key? key, required this.onBack})
      : super(key: key);

  @override
  _AdminMembershipRequestsState createState() =>
      _AdminMembershipRequestsState();
}

class _AdminMembershipRequestsState extends State<AdminMembershipRequests> {
  final CollectionReference _requestsRef =
  FirebaseFirestore.instance.collection('membership_requests');

  final CollectionReference _membersRef =
  FirebaseFirestore.instance.collection('members');

  // Departments
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

  // Roles
  final List<String> roles = [
    'Member',
    'Admin',
  ];

  // Temp selected values
  Map<String, String> selectedDepartments = {};
  Map<String, String> selectedRoles = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Membership Requests"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _requestsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No membership requests."),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? '';
              final location = data['location'] ?? '';
              final status = data['status'] ?? 'pending';

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Email: $email"),
                      Text("Phone: $phone"),
                      Text("Location: $location"),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'approved'
                              ? Colors.green
                              : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (status == 'pending') ...[
                        DropdownButtonFormField<String>(
                          value: selectedDepartments[doc.id],
                          hint: const Text("Select Department"),
                          items: departments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDepartments[doc.id] = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRoles[doc.id],
                          hint: const Text("Select Role"),
                          items: roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRoles[doc.id] = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: Colors.green),
                              onPressed: () {
                                if (selectedDepartments[doc.id] == null ||
                                    selectedRoles[doc.id] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Please select department and role first")),
                                  );
                                  return;
                                }
                                _approveRequest(
                                    doc.id,
                                    data,
                                    selectedDepartments[doc.id]!,
                                    selectedRoles[doc.id]!);
                              },
                            ),
                            IconButton(
                              icon:
                              const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  _updateStatus(doc.id, 'rejected'),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveRequest(String docId, Map<String, dynamic> requestData,
      String department, String role) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final approverName =
          currentUser?.displayName ?? currentUser?.email ?? "Admin";

      // Add to members collection
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

      // Delete request from membership_requests after approval
      await _requestsRef.doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Request approved, moved to Members, and removed from Requests')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  void _updateStatus(String docId, String newStatus) async {
    try {
      await _requestsRef.doc(docId).update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}

