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

  String searchTerm = '';
  String selectedDepartment = 'all';

  List<model.Member> membersList = [];
  bool isLoading = true;

  // 🔹 Predefined departments
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
  }

  void _listenToAllMembers() async {
    // Listen to members collection
    _firestore.collection('members').snapshots().listen((membersSnap) async {
      List<model.Member> members = membersSnap.docs
          .map((doc) => model.Member.fromMap(doc.id, doc.data()))
          .toList();

      // Fetch approved membership requests
      final requestsSnap = await _firestore
          .collection('membership_requests')
          .where('status', isEqualTo: 'approved')
          .get();

      List<model.Member> approved = requestsSnap.docs
          .map((doc) => model.Member.fromMap(doc.id, doc.data()))
          .toList();

      setState(() {
        membersList = [...members, ...approved];
        isLoading = false;
      });
    });
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

      final dept = member.department.isEmpty ? 'Unassigned' : member.department;
      final matchesDepartment =
          selectedDepartment == 'all' || dept == selectedDepartment;

      return matchesSearch && matchesDepartment;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Members Directory"),
        leading:
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔎 Search & Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText:
                      "Search by name, email, phone, or location...",
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => searchTerm = val),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedDepartment,
                  borderRadius: BorderRadius.circular(12),
                  items: departmentsList
                      .map((dept) => DropdownMenuItem(
                    value: dept,
                    child: Text(dept == 'all'
                        ? 'All Departments'
                        : dept),
                  ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedDepartment = val);
                    }
                  },
                ),
              ],
            ),
          ),

          // 🧑 Members List
          Expanded(
            child: filteredMembers.isEmpty
                ? const Center(
              child: Text(
                "No members found matching your search criteria.",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => widget.onSelectMember(member),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      child: Text(
                        member.name
                            .trim()
                            .split(' ')
                            .map((n) => n[0])
                            .take(2)
                            .join(),
                        style:
                        TextStyle(color: Colors.purple[600]),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(member.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        if (member.role == "admin")
                          Container(
                            margin:
                            const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Admin",
                              style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            member.department.isEmpty
                                ? "Unassigned"
                                : member.department,
                            style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          "Location: ${member.location.isEmpty ? 'N/A' : member.location}",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.email,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(member.email,
                                style: const TextStyle(
                                    color: Colors.grey)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(member.phone,
                                style: const TextStyle(
                                    color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 📊 Summary
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Showing ${filteredMembers.length} of ${membersList.length} members",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

