import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String fromDate;
  final String fromTime;
  final String toDate;
  final String toTime;
  final String location;
  final String category;
  int attendees;
  final int? maxAttendees;
  bool isRegistered;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.fromDate,
    required this.fromTime,
    required this.toDate,
    required this.toTime,
    required this.location,
    required this.category,
    required this.attendees,
    this.maxAttendees,
    this.isRegistered = false,
  });

  factory Event.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    bool registered = false;
    if (data['registrations'] != null && data['registrations'][userId] != null) {
      registered = data['registrations'][userId];
    }
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fromDate: data['fromDate'] ?? '',
      fromTime: data['fromTime'] ?? '',
      toDate: data['toDate'] ?? '',
      toTime: data['toTime'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? 'service',
      attendees: data['attendees'] ?? 0,
      maxAttendees: data['maxAttendees'],
      isRegistered: registered,
    );
  }
}

class EventsPage extends StatefulWidget {
  final VoidCallback onBack;
  const EventsPage({super.key, required this.onBack});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String selectedCategory = 'all';
  final List<String> categories = [
    'all',
    'service',
    'fellowship',
    'outreach',
    'conference',
    'special',
  ];

  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  void toggleRegister(Event event) async {
    if (event.maxAttendees != null &&
        event.attendees >= event.maxAttendees! &&
        !event.isRegistered) return;

    setState(() {
      if (event.isRegistered) {
        event.attendees--;
        event.isRegistered = false;
      } else {
        event.attendees++;
        event.isRegistered = true;
      }
    });

    final docRef = FirebaseFirestore.instance.collection('events').doc(event.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentData = snapshot.data() as Map<String, dynamic>;
      final registrations = Map<String, dynamic>.from(currentData['registrations'] ?? {});
      registrations[userId] = event.isRegistered;
      transaction.update(docRef, {
        'attendees': event.attendees,
        'registrations': registrations,
      });
    });
  }

  void addToCalendar(Event event) async {
    final startDate =
    DateTime.parse('${event.fromDate} ${_convertTo24Hour(event.fromTime)}');
    final endDate =
    DateTime.parse('${event.toDate} ${_convertTo24Hour(event.toTime)}');

    final String start = startDate
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[-:]'), '')
        .split('.')
        .first + 'Z';
    final String end = endDate
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[-:]'), '')
        .split('.')
        .first + 'Z';

    final String url =
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(event.title)}&dates=$start/$end&details=${Uri.encodeComponent(event.description)}&location=${Uri.encodeComponent(event.location)}';

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Calendar')),
      );
    }
  }

  String _convertTo24Hour(String time) {
    final format = time.split(' ');
    final parts = format[0].split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = format[1];

    if (period.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events & Announcements"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: categories.map((category) {
                bool selected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      category == 'all' ? 'All Events' : category,
                      style: const TextStyle(color: Colors.white),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: Colors.purple,
                    backgroundColor: Colors.grey.shade400,
                  ),
                );
              }).toList(),
            ),
          ),

          // Events List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('fromDate')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEvents = snapshot.data!.docs
                    .map((doc) => Event.fromFirestore(doc, userId))
                    .toList();

                final filteredEvents = selectedCategory == 'all'
                    ? allEvents
                    : allEvents
                    .where((e) => e.category == selectedCategory)
                    .toList();

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_today,
                            size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No events found for the selected category"),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(event.title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text(event.category),
                                  backgroundColor: Colors.purple.shade100,
                                  labelStyle:
                                  const TextStyle(color: Colors.purple),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(event.description,
                                style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 12),

                            // From – To Date & Time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text("${event.fromDate} ${event.fromTime}"),
                                ]),
                                Row(children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text("${event.toDate} ${event.toTime}"),
                                ]),
                                Row(children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 4),
                                  Text(event.location),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Attendees
                            Row(
                              children: [
                                const Icon(Icons.people, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                    "${event.attendees} attendees${event.maxAttendees != null ? ' / ${event.maxAttendees}' : ''}"),
                                if (event.maxAttendees != null)
                                  Expanded(
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.only(left: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: event.attendees /
                                              event.maxAttendees!,
                                          minHeight: 6,
                                          color: Colors.purple,
                                          backgroundColor: Colors.grey[300],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add to Calendar"),
                                    onPressed: () => addToCalendar(event),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: event.isRegistered
                                          ? Colors.red
                                          : Colors.purple,
                                    ),
                                    onPressed: () => toggleRegister(event),
                                    child: Text(event.isRegistered
                                        ? "Unregister"
                                        : "Register"),
                                  ),
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
          ),
        ],
      ),
    );
  }
}

