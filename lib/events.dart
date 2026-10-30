import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// COLORS
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color gold = Color(0xFFFFD700);
const Color backgroundWhite = Color(0xFFF8F7FC);

// ============================================================
// DATE HELPERS
// ============================================================

DateTime? _parseDateValue(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }

  return null;
}

DateTime? _parseDateAndTime(dynamic dateValue, dynamic timeValue) {
  final date = _parseDateValue(dateValue);
  if (date == null) return null;

  if (timeValue == null || timeValue.toString().trim().isEmpty) {
    return DateTime(date.year, date.month, date.day);
  }

  final time = timeValue.toString().trim().toUpperCase();
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$',
  ).firstMatch(time);

  if (match == null) return null;

  int hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final second = int.tryParse(match.group(3) ?? '0') ?? 0;
  final period = match.group(4);

  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  if (hour > 23 || minute > 59 || second > 59) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
    second,
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return '';

  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime? date) {
  if (date == null) return '';

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '${hour.toString().padLeft(2, '0')}:$minute $period';
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

// ============================================================
// EVENT MODEL
// ============================================================

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

  final DateTime? startDateTime;
  final DateTime? endDateTime;

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
    this.startDateTime,
    this.endDateTime,
  });

  factory Event.fromFirestore(DocumentSnapshot doc, String userId) {
    final rawData = doc.data();
    final data = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    final startTimestamp = _parseDateValue(data['startAt']);
    final endTimestamp = _parseDateValue(data['endAt']);

    final parsedStart = _parseDateAndTime(
      data['fromDate'],
      data['fromTime'],
    );

    final parsedEnd = _parseDateAndTime(
      data['toDate'],
      data['toTime'],
    );

    final start = startTimestamp ?? parsedStart;
    final end = endTimestamp ?? parsedEnd;

    final fromDate = data['fromDate']?.toString().trim().isNotEmpty == true
        ? data['fromDate'].toString()
        : _formatDate(start);

    final fromTime = data['fromTime']?.toString().trim().isNotEmpty == true
        ? data['fromTime'].toString()
        : _formatTime(start);

    final toDate = data['toDate']?.toString().trim().isNotEmpty == true
        ? data['toDate'].toString()
        : _formatDate(end);

    final toTime = data['toTime']?.toString().trim().isNotEmpty == true
        ? data['toTime'].toString()
        : _formatTime(end);

    final rawRegistrations = data['registrations'];
    final registrations = rawRegistrations is Map
        ? rawRegistrations
        : <dynamic, dynamic>{};

    final registered = registrations[userId] == true;

    final rawMaxAttendees = data['maxAttendees'];
    final maxAttendees = rawMaxAttendees == null
        ? null
        : _toInt(rawMaxAttendees);

    return Event(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      fromDate: fromDate,
      fromTime: fromTime,
      toDate: toDate,
      toTime: toTime,
      location: data['location']?.toString() ?? '',
      category: data['category']?.toString().toLowerCase() ?? 'service',
      attendees: _toInt(data['attendees']),
      maxAttendees: maxAttendees,
      isRegistered: registered,
      startDateTime: start,
      endDateTime: end,
    );
  }
}

// ============================================================
// EVENTS PAGE
// ============================================================

class EventsPage extends StatefulWidget {
  final VoidCallback onBack;

  const EventsPage({
    super.key,
    required this.onBack,
  });

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

  final Set<String> _busyEventIds = {};

  // ==========================================================
  // CACHED FIRESTORE STREAM
  // ==========================================================

  late final Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();

    // Create the stream once.
    // Rebuilding this page will reuse the same stream subscription.
    _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .snapshots();
  }

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // ==========================================================
  // REGISTER / UNREGISTER
  // ==========================================================

  Future<void> toggleRegister(Event event) async {
    if (userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to register for an event.'),
        ),
      );
      return;
    }

    if (_busyEventIds.contains(event.id)) return;

    setState(() {
      _busyEventIds.add(event.id);
    });

    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(event.id);

    try {
      final result = await FirebaseFirestore.instance.runTransaction(
            (transaction) async {
          final snapshot = await transaction.get(docRef);

          if (!snapshot.exists) {
            throw Exception('This event no longer exists.');
          }

          final data = snapshot.data() as Map<String, dynamic>? ??
              <String, dynamic>{};

          final rawRegistrations = data['registrations'];
          final registrations = rawRegistrations is Map
              ? Map<String, dynamic>.from(rawRegistrations)
              : <String, dynamic>{};

          final wasRegistered = registrations[userId] == true;
          final shouldRegister = !wasRegistered;

          int attendees = _toInt(data['attendees']);

          final rawMax = data['maxAttendees'];
          final maxAttendees =
          rawMax == null ? null : _toInt(rawMax);

          // Check capacity using the latest Firestore values.
          if (shouldRegister &&
              maxAttendees != null &&
              maxAttendees > 0 &&
              attendees >= maxAttendees) {
            throw Exception('This event is already full.');
          }

          if (shouldRegister) {
            attendees++;
            registrations[userId] = true;
          } else {
            if (attendees > 0) attendees--;
            registrations.remove(userId);
          }

          transaction.update(docRef, {
            'attendees': attendees,
            'registrations': registrations,
          });

          return <String, dynamic>{
            'registered': shouldRegister,
            'attendees': attendees,
          };
        },
      );

      if (!mounted) return;

      setState(() {
        event.isRegistered = result['registered'] as bool;
        event.attendees = result['attendees'] as int;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.isRegistered
                ? 'You have successfully registered for this event.'
                : 'You have been unregistered from this event.',
          ),
          backgroundColor: event.isRegistered
              ? Colors.green.shade700
              : purple,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update registration: $message'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyEventIds.remove(event.id);
        });
      }
    }
  }

  // ==========================================================
  // GOOGLE CALENDAR
  // ==========================================================

  String _googleCalendarDate(DateTime date) {
    final utc = date.toUtc();

    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  Future<void> addToCalendar(Event event) async {
    try {
      final start = event.startDateTime ??
          _parseDateAndTime(event.fromDate, event.fromTime);

      final end = event.endDateTime ??
          _parseDateAndTime(event.toDate, event.toTime) ??
          start;

      if (start == null) {
        throw Exception('The event start date or time is invalid.');
      }

      final calendarUri = Uri.https(
        'calendar.google.com',
        '/calendar/render',
        {
          'action': 'TEMPLATE',
          'text': event.title,
          'dates':
          '${_googleCalendarDate(start)}/${_googleCalendarDate(end ?? start)}',
          'details': event.description,
          'location': event.location,
        },
      );

      if (!await launchUrl(
        calendarUri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not open Google Calendar.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to add event to calendar. Check the event date and time.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // CATEGORY COLORS
  // ==========================================================

  List<Color> _categoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'service':
        return const [purple, purpleLight];
      case 'fellowship':
        return const [Color(0xFF0F766E), Color(0xFF2DD4BF)];
      case 'outreach':
        return const [Color(0xFFEA580C), Color(0xFFFB923C)];
      case 'conference':
        return const [Color(0xFF2563EB), Color(0xFF60A5FA)];
      case 'special':
        return const [Color(0xFFD97706), gold];
      default:
        return const [purple, purpleLight];
    }
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'service':
        return Icons.church_rounded;
      case 'fellowship':
        return Icons.groups_rounded;
      case 'outreach':
        return Icons.volunteer_activism_rounded;
      case 'conference':
        return Icons.mic_rounded;
      case 'special':
        return Icons.star_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  // ==========================================================
  // DATE HELPERS
  // ==========================================================

  String _monthName(String date) {
    try {
      final parsed = DateTime.parse(date);
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
      ];
      return months[parsed.month - 1];
    } catch (_) {
      return '';
    }
  }

  String _dayNumber(String date) {
    try {
      return DateTime.parse(date).day.toString().padLeft(2, '0');
    } catch (_) {
      return '--';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  // ==========================================================
  // EVENT DETAILS — FULL DESCRIPTION
  // ==========================================================

  void _showEventDetails(Event event) {
    final colors = _categoryColors(event.category);

    final isFull = event.maxAttendees != null &&
        event.attendees >= event.maxAttendees! &&
        !event.isRegistered;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 5, 22, 30),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _capitalize(event.category),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${event.fromDate} • ${event.fromTime}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'About This Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF252033),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.description.trim().isEmpty
                              ? 'No description has been provided for this event.'
                              : event.description,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.75,
                            color: Color(0xFF55515F),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Event Information',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF252033),
                          ),
                        ),
                        const SizedBox(height: 17),
                        _DetailItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'Start Date',
                          value: event.fromDate.isEmpty
                              ? 'Not specified'
                              : event.fromDate,
                          color: colors.first,
                        ),
                        _DetailItem(
                          icon: Icons.event_available_rounded,
                          title: 'End Date',
                          value: event.toDate.isEmpty
                              ? 'Not specified'
                              : event.toDate,
                          color: colors.first,
                        ),
                        _DetailItem(
                          icon: Icons.access_time_rounded,
                          title: 'Event Time',
                          value: '${event.fromTime} – ${event.toTime}',
                          color: colors.first,
                        ),
                        _DetailItem(
                          icon: Icons.location_on_rounded,
                          title: 'Location',
                          value: event.location.isEmpty
                              ? 'Not specified'
                              : event.location,
                          color: colors.first,
                        ),
                        _DetailItem(
                          icon: Icons.people_alt_rounded,
                          title: 'Attendance',
                          value: event.maxAttendees != null
                              ? '${event.attendees} / ${event.maxAttendees} attendees'
                              : '${event.attendees} attendees',
                          color: colors.first,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              addToCalendar(event);
                            },
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: const Text('Add to Google Calendar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.first,
                              side: BorderSide(
                                color: colors.first,
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                            isFull || _busyEventIds.contains(event.id)
                                ? null
                                : () {
                              Navigator.pop(sheetContext);
                              toggleRegister(event);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: event.isRegistered
                                  ? Colors.red.shade600
                                  : colors.first,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              event.isRegistered
                                  ? 'Unregister from Event'
                                  : isFull
                                  ? 'Event Fully Booked'
                                  : 'Register for Event',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4C087A),
              Color(0xFF6A0DAD),
              Color(0xFF8B5CF6),
              Color(0xFFFFD700),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildCategoryFilters(),
              Expanded(child: _buildEventsStream()),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Row(
            children: [
              _TopBarButton(
                icon: Icons.arrow_back_rounded,
                onTap: widget.onBack,
              ),
              const SizedBox(width: 13),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, purpleLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.23),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events & Announcements',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202124),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Discover upcoming church activities',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w500,
                      ),
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

  // ==========================================================
  // CATEGORY FILTERS
  // ==========================================================

  Widget _buildCategoryFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: categories.map((category) {
                final selected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            selected ? 0.9 : 0.25,
                          ),
                        ),
                        boxShadow: selected
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category == 'all'
                                ? Icons.apps_rounded
                                : _categoryIcon(category),
                            size: 17,
                            color: selected ? purple : Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            category == 'all'
                                ? 'All Events'
                                : _capitalize(category),
                            style: TextStyle(
                              color: selected ? purple : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EVENTS STREAM — RESPONSIVE GRID
  // ==========================================================

  Widget _buildEventsStream() {
    return StreamBuilder<QuerySnapshot>(
      // Reuse the stream initialized in initState().
      stream: _eventsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final allEvents = snapshot.data?.docs
            .map((doc) => Event.fromFirestore(doc, userId))
            .toList() ??
            [];

        // Sort locally using the actual event start time.
        allEvents.sort((a, b) {
          final aDate = a.startDateTime ??
              _parseDateAndTime(a.fromDate, a.fromTime);
          final bDate = b.startDateTime ??
              _parseDateAndTime(b.fromDate, b.fromTime);

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return aDate.compareTo(bDate);
        });

        final filteredEvents = selectedCategory == 'all'
            ? allEvents
            : allEvents
            .where(
              (event) =>
          event.category.toLowerCase() ==
              selectedCategory.toLowerCase(),
        )
            .toList();

        if (filteredEvents.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            final columns = screenWidth < 600
                ? 1
                : screenWidth < 1000
                ? 2
                : 3;

            final double cardHeight = columns == 1
                ? 540
                : columns == 2
                ? 530
                : 520;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1250),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  itemCount: filteredEvents.length,
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 20,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];

                    return _AnimatedEventCard(
                      // Stable identity prevents cards from being
                      // recreated when Firestore sends an update.
                      key: ValueKey(event.id),
                      index: index,
                      child: _buildEventCard(event),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // EVENT CARD
  // ==========================================================

  Widget _buildEventCard(Event event) {
    final colors = _categoryColors(event.category);

    final isFull = event.maxAttendees != null &&
        event.attendees >= event.maxAttendees! &&
        !event.isRegistered;

    final isBusy = _busyEventIds.contains(event.id);

    final double progress =
    event.maxAttendees != null && event.maxAttendees! > 0
        ? (event.attendees / event.maxAttendees!).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 128,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    right: -30,
                    top: -40,
                    child: Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    bottom: -55,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 68,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _monthName(event.fromDate),
                                style: TextStyle(
                                  color: colors.first,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _dayNumber(event.fromDate),
                                style: const TextStyle(
                                  color: Color(0xFF252033),
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.19),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _categoryIcon(event.category),
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _capitalize(event.category),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.description.trim().isEmpty
                          ? 'No description available.'
                          : event.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF55515F),
                        fontSize: 14,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      title: 'TIME',
                      value: '${event.fromTime} – ${event.toTime}',
                      color: colors.first,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      title: 'LOCATION',
                      value: event.location.isEmpty
                          ? 'Not specified'
                          : event.location,
                      color: colors.first,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.first.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.people_alt_rounded,
                            color: colors.first,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.maxAttendees != null
                                    ? '${event.attendees} / ${event.maxAttendees} attendees'
                                    : '${event.attendees} attendees',
                                style: const TextStyle(
                                  color: Color(0xFF35313E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (event.maxAttendees != null) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor:
                                    const Color(0xFFEDEAF1),
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      colors.first,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 16,
                          color: colors.first,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap card to read full details',
                          style: TextStyle(
                            color: colors.first,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => addToCalendar(event),
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                            ),
                            label: const Text('Calendar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.first,
                              side: BorderSide(
                                color: colors.first.withOpacity(0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 5,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isFull || isBusy
                                ? null
                                : () => toggleRegister(event),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: event.isRegistered
                                  ? Colors.red.shade600
                                  : colors.first,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 5,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isBusy
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              event.isRegistered
                                  ? 'Unregister'
                                  : isFull
                                  ? 'Full'
                                  : 'Register',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: purple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 36,
                color: purple,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'No Events Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF252033),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no events in this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to Load Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EVENT DETAILS ITEM
// ============================================================

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9993A2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF302B38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9993A2),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Color(0xFF302B38),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TOP BAR BUTTON
// ============================================================

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECFA),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: purple.withOpacity(0.08),
            ),
          ),
          child: Icon(icon, color: purple, size: 21),
        ),
      ),
    );
  }
}

// ============================================================
// EVENT CARD ANIMATION
// ============================================================

class _AnimatedEventCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedEventCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<_AnimatedEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 450 + (widget.index * 60),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Keep the original staggered entrance animation.
    Future.delayed(
      Duration(milliseconds: widget.index * 50),
          () {
        if (mounted && !_controller.isAnimating) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}