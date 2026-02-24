import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}

class AdminPrayerRequests extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;

  AdminPrayerRequests({Key? key}) : super(key: key);

  Future<void> _updateStatus(String id, String status) async {
    await _firestore.collection("prayer_requests").doc(id).update({
      "status": status,
    });
  }

  Widget _getStatusChip(String status) {
    switch (status) {
      case "pending":
        return Chip(label: Text("Pending"), backgroundColor: Colors.grey[300]);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prayer Requests"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("prayer_requests")
            .orderBy("dateSubmitted", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs
              .map((doc) => PrayerRequest.fromFirestore(doc))
              .toList();

          if (requests.isEmpty) {
            return const Center(child: Text("No prayer requests found."));
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
                      // Title & Urgent Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(req.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          if (req.isUrgent)
                            Chip(
                              label: const Text("Urgent"),
                              backgroundColor: Colors.red,
                              labelStyle:
                              const TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "by ${req.name} • ${req.dateSubmitted}",
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(req.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _getStatusChip(req.status),
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (status) =>
                                _updateStatus(req.id, status),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "pending",
                                child: Text("Mark as Pending"),
                              ),
                              const PopupMenuItem(
                                value: "praying",
                                child: Text("Mark as Praying"),
                              ),
                              const PopupMenuItem(
                                value: "answered",
                                child: Text("Mark as Answered"),
                              ),
                            ],
                            child: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
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
}
