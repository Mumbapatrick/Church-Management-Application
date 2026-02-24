import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrayerRequest {
  final String id;
  final String name;
  final String category;
  final String title;
  final String description;
  final bool isAnonymous;
  final bool isUrgent;
  final String dateSubmitted;
  final String status;

  PrayerRequest({
    required this.id,
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
    final data = doc.data() as Map<String, dynamic>;
    return PrayerRequest(
      id: doc.id,
      name: data['name'] ?? 'Anonymous',
      category: data['category'] ?? 'general',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
      isUrgent: data['isUrgent'] ?? false,
      dateSubmitted: data['dateSubmitted'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "category": category,
      "title": title,
      "description": description,
      "isAnonymous": isAnonymous,
      "isUrgent": isUrgent,
      "dateSubmitted": dateSubmitted,
      "status": status,
    };
  }
}

class PrayerRequests extends StatefulWidget {
  final VoidCallback onBack;

  const PrayerRequests({Key? key, required this.onBack}) : super(key: key);

  @override
  State<PrayerRequests> createState() => _PrayerRequestsState();
}

class _PrayerRequestsState extends State<PrayerRequests>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isAnonymous = false;
  bool _isUrgent = false;

  final List<Map<String, String>> _categories = [
    {"value": "personal", "label": "Personal"},
    {"value": "family", "label": "Family"},
    {"value": "healing", "label": "Healing"},
    {"value": "ministry", "label": "Ministry"},
  ];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final user = _auth.currentUser;
    final name = _isAnonymous
        ? "Anonymous"
        : (user?.displayName ?? user?.email ?? "Unknown User");

    await _firestore.collection("prayer_requests").add({
      "name": name,
      "category": _selectedCategory,
      "title": _titleController.text,
      "description": _descriptionController.text,
      "isAnonymous": _isAnonymous,
      "isUrgent": _isUrgent,
      "dateSubmitted": DateTime.now().toIso8601String(),
      "status": "pending",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prayer request submitted successfully")),
    );

    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _isAnonymous = false;
      _isUrgent = false;
    });
  }

  Widget _getStatusChip(String status) {
    switch (status) {
      case "pending":
        return Chip(label: Text("Pending"), backgroundColor: Colors.grey[200]);
      case "praying":
        return Chip(label: Text("Praying"), backgroundColor: Colors.purple[200]);
      case "answered":
        return Chip(
          label: Text("Answered"),
          backgroundColor: Colors.green,
          labelStyle: const TextStyle(color: Colors.white),
        );
      default:
        return const Chip(label: Text("Unknown"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Prayer Requests",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text("Submit and view prayer requests",
                            style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.purple,
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Submit Request"),
                  Tab(text: "View Requests"),
                ],
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Submit Request Tab
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: "Prayer Request Title *",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: "Select a category *",
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text("Select a category *"),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat["value"],
                                child: Text(cat["label"]!),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: "Prayer Request Details *",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _isAnonymous,
                            onChanged: (val) =>
                                setState(() => _isAnonymous = val ?? false),
                            title: const Text("Submit anonymously"),
                          ),
                          CheckboxListTile(
                            value: _isUrgent,
                            onChanged: (val) =>
                                setState(() => _isUrgent = val ?? false),
                            title: const Text("Mark as urgent"),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            icon: const Icon(Icons.send),
                            label: const Text("Submit Prayer Request"),
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
                    ),

                    // View Requests Tab
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection("prayer_requests")
                          .orderBy("dateSubmitted", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final requests = snapshot.data!.docs
                            .map((doc) => PrayerRequest.fromFirestore(doc))
                            .toList();

                        if (requests.isEmpty) {
                          return const Center(
                            child: Text("No prayer requests found."),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title & badges
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(req.title,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Row(
                                          children: [
                                            if (req.isUrgent)
                                              Chip(
                                                label: const Text("Urgent"),
                                                backgroundColor: Colors.red,
                                                labelStyle: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            const SizedBox(width: 6),
                                            _getStatusChip(req.status),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        "by ${req.name} • ${req.dateSubmitted}",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Text(req.description),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.favorite_border,
                                            color: Colors.purple),
                                        label: const Text("Pray for this",
                                            style:
                                            TextStyle(color: Colors.purple)),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "You prayed for ${req.title}")),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
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
}
