import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Meeting Model
class Meeting {
  String id;
  String date;
  String time;
  int duration;
  String purpose;
  String description;
  String status;
  String memberName;
  String memberPhone;
  String memberEmail;

  Meeting({
    required this.id,
    required this.date,
    required this.time,
    required this.duration,
    required this.purpose,
    required this.description,
    required this.status,
    required this.memberName,
    required this.memberPhone,
    required this.memberEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'time': time,
      'duration': duration,
      'purpose': purpose,
      'description': description,
      'status': status,
      'memberName': memberName,
      'memberPhone': memberPhone,
      'memberEmail': memberEmail,
    };
  }

  factory Meeting.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meeting(
      id: doc.id,
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      duration: data['duration'] ?? 60,
      purpose: data['purpose'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      memberName: data['memberName'] ?? '',
      memberPhone: data['memberPhone'] ?? '',
      memberEmail: data['memberEmail'] ?? '',
    );
  }
}

class MeetingScheduler extends StatefulWidget {
  const MeetingScheduler({super.key, required void Function() onBack});

  @override
  State<MeetingScheduler> createState() => _MeetingSchedulerState();
}

class _MeetingSchedulerState extends State<MeetingScheduler>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? selectedDate;
  String? selectedTime;
  String duration = '60';
  String? selectedPurpose;

  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ✅ Schedule Meeting
  void handleSchedule() async {
    if (selectedDate == null ||
        selectedTime == null ||
        selectedPurpose == null ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    final meeting = Meeting(
      id: '',
      date: selectedDate!,
      time: selectedTime!,
      duration: int.parse(duration),
      purpose: selectedPurpose!,
      description: descriptionController.text,
      status: 'pending',
      memberName: 'Member Name', // TODO: Replace with logged-in user
      memberPhone: phoneController.text,
      memberEmail: emailController.text,
    );

    // Save meeting request
    await FirebaseFirestore.instance
        .collection('meetings')
        .add(meeting.toMap());

    // ✅ Update availability (remove booked slot immediately)
    final docRef =
    FirebaseFirestore.instance.collection('availability').doc(meeting.date);

    final doc = await docRef.get();
    if (doc.exists) {
      List<dynamic> slots = doc['availableSlots'] ?? [];
      slots.remove(meeting.time); // remove booked slot
      await docRef.update({'availableSlots': slots});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Meeting request submitted! Await approval.")),
    );

    // Reset form
    setState(() {
      selectedDate = null;
      selectedTime = null;
      duration = '60';
      selectedPurpose = null;
      descriptionController.clear();
      phoneController.clear();
      emailController.clear();
    });
  }

  Widget getStatusBadge(String status) {
    switch (status) {
      case 'pending':
        return const Chip(label: Text("Pending"), backgroundColor: Colors.grey);
      case 'confirmed':
        return const Chip(
          label: Text("Confirmed"),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        );
      case 'completed':
        return const Chip(
          label: Text("Completed"),
          backgroundColor: Colors.blue,
          labelStyle: TextStyle(color: Colors.white),
        );
      case 'cancelled':
        return const Chip(
          label: Text("Cancelled"),
          backgroundColor: Colors.red,
          labelStyle: TextStyle(color: Colors.white),
        );
      default:
        return const Chip(label: Text("Unknown"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meetings"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Schedule"),
            Tab(text: "My Meetings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 🟢 Tab 1: Schedule Meeting
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ Available Dates Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('availability')
                        .orderBy('date')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text("No available dates set by admin.");
                      }

                      final docs = snapshot.data!.docs;
                      final dates = docs.map((d) => d.id).toList();

                      return DropdownButtonFormField<String>(
                        decoration:
                        const InputDecoration(labelText: "Select Date *"),
                        value: selectedDate,
                        items: dates
                            .map((d) =>
                            DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDate = value;
                            selectedTime = null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // ✅ Available Slots
                  if (selectedDate != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('availability')
                          .doc(selectedDate)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text("No available slots for this date.");
                        }

                        final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                        List<String> slots =
                        List<String>.from(data['availableSlots'] ?? []);

                        // ✅ Remove duplicates
                        slots = slots.toSet().toList();

                        if (slots.isEmpty) {
                          return const Text("No available slots for this date.");
                        }

                        // ✅ Reset selectedTime if slot no longer exists
                        if (selectedTime != null &&
                            !slots.contains(selectedTime)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              selectedTime = null;
                            });
                          });
                        }

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: "Select Time *"),
                          value: selectedTime,
                          items: slots
                              .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedTime = value),
                        );
                      },
                    ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    decoration:
                    const InputDecoration(labelText: "Duration (min)"),
                    value: duration,
                    items: ['30', '60', '90']
                        .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) => setState(() => duration = value!),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    decoration:
                    const InputDecoration(labelText: "Purpose *"),
                    value: selectedPurpose,
                    items: ['Counseling', 'Prayer', 'Deliverance Cases', 'Mentorship / Guidance', 'Bible Study / Spiritual Growth',
                    'Leadership Training', 'Conflict Resolution / Mediation', 'Youth Fellowship', 'Marriage & Family Support',
                    'Career / Academic Guidance', 'Financial Guidance']
                        .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedPurpose = value),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number *",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: handleSchedule,
                    child: const Text("Submit Request"),
                  ),
                ],
              ),
            ),
          ),

          // 🟡 Tab 2: My Meetings
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('meetings')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final meetings = snapshot.data!.docs
                  .map((doc) => Meeting.fromDoc(doc))
                  .toList();

              if (meetings.isEmpty) {
                return const Center(child: Text("No meetings found."));
              }

              return ListView.builder(
                itemCount: meetings.length,
                itemBuilder: (context, index) {
                  final meeting = meetings[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text("${meeting.purpose}"),
                      subtitle: Text(
                          "${meeting.date} at ${meeting.time}\n${meeting.description}"),
                      trailing: getStatusBadge(meeting.status),
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

