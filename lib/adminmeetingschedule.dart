import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminMeetingSchedule extends StatefulWidget {
  const AdminMeetingSchedule({super.key});

  @override
  State<AdminMeetingSchedule> createState() => _AdminMeetingScheduleState();
}

class _AdminMeetingScheduleState extends State<AdminMeetingSchedule>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? selectedDate;
  List<String> selectedSlots = [];

  final List<String> timeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Save availability to Firestore
  Future<void> saveAvailability() async {
    if (selectedDate == null || selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date and at least one slot")),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);

    await FirebaseFirestore.instance.collection('availability').doc(dateStr).set({
      'date': dateStr,
      'availableSlots': selectedSlots,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Availability saved")),
    );

    setState(() {
      selectedDate = null;
      selectedSlots = [];
    });
  }

  /// Update meeting status
  Future<void> updateMeetingStatus(String meetingId, String status) async {
    await FirebaseFirestore.instance.collection('meetings').doc(meetingId).update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointments & Meetings"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Set Availability"),
            Tab(text: "Manage Meetings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ======== Tab 1: Set Availability ========
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text("Select Date"),
                  subtitle: Text(selectedDate == null
                      ? "No date chosen"
                      : DateFormat.yMMMd().format(selectedDate!)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: timeSlots.map((slot) {
                    final isSelected = selectedSlots.contains(slot);
                    return FilterChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            selectedSlots.add(slot);
                          } else {
                            selectedSlots.remove(slot);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: saveAvailability,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Availability"),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                )
              ],
            ),
          ),

          // ======== Tab 2: Manage Meetings ========
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('meetings')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final meetings = snapshot.data!.docs;

              if (meetings.isEmpty) {
                return const Center(child: Text("No meeting requests yet."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: meetings.length,
                itemBuilder: (context, index) {
                  final doc = meetings[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text("${data['purpose']} (${data['status']})"),
                      subtitle: Text(
                        "${data['date']} at ${data['time']}\n"
                            "Member: ${data['memberName']} - ${data['memberPhone']}",
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (status) =>
                            updateMeetingStatus(doc.id, status),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: "confirmed", child: Text("Confirm")),
                          PopupMenuItem(value: "completed", child: Text("Mark Completed")),
                          PopupMenuItem(value: "cancelled", child: Text("Cancel")),
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
    );
  }
}
