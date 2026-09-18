import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// COLORS — CONSISTENT WITH ADMIN DASHBOARD / AUTH
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);

const Color gold = Color(0xFFFFD700);
const Color backgroundWhite = Color(0xFFF8F7FC);

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

factory Event.fromFirestore(
DocumentSnapshot doc,
String userId,
) {
final data =
doc.data() as Map<String, dynamic>;

bool registered = false;

if (data['registrations'] != null &&
data['registrations'][userId] != null) {
registered =
data['registrations'][userId] == true;
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
maxAttendees:
data['maxAttendees'] is num
? (data['maxAttendees'] as num).toInt()
    : null,
isRegistered: registered,
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
State<EventsPage> createState() =>
_EventsPageState();
}

class _EventsPageState
extends State<EventsPage> {
String selectedCategory = 'all';

final List<String> categories = [
'all',
'service',
'fellowship',
'outreach',
'conference',
'special',
];

final String userId =
FirebaseAuth.instance.currentUser?.uid ??
'guest';

// ==========================================================
// REGISTER / UNREGISTER
// ==========================================================

Future<void> toggleRegister(Event event) async {
if (event.maxAttendees != null &&
event.attendees >=
event.maxAttendees! &&
!event.isRegistered) {
ScaffoldMessenger.of(context)
    .showSnackBar(
const SnackBar(
content:
Text('This event is already full.'),
),
);

return;
}

final bool newRegistration =
!event.isRegistered;

// Optimistic UI
setState(() {
event.isRegistered =
newRegistration;

if (newRegistration) {
event.attendees++;
} else if (event.attendees > 0) {
event.attendees--;
}
});

try {
final docRef = FirebaseFirestore
    .instance
    .collection('events')
    .doc(event.id);

await FirebaseFirestore.instance
    .runTransaction(
(transaction) async {
final snapshot =
await transaction.get(docRef);

if (!snapshot.exists) {
throw Exception(
'Event no longer exists.',
);
}

final currentData =
snapshot.data()
as Map<String, dynamic>;

final registrations =
Map<String, dynamic>.from(
currentData['registrations'] ??
{},
);

int currentAttendees =
currentData['attendees'] ?? 0;

final bool wasRegistered =
registrations[userId] == true;

if (newRegistration &&
!wasRegistered) {
currentAttendees++;
} else if (!newRegistration &&
wasRegistered &&
currentAttendees > 0) {
currentAttendees--;
}

registrations[userId] =
newRegistration;

transaction.update(
docRef,
{
'attendees':
currentAttendees,
'registrations':
registrations,
},
);
},
);
} catch (e) {
// Restore UI if transaction fails.
setState(() {
event.isRegistered =
!newRegistration;

if (newRegistration &&
event.attendees > 0) {
event.attendees--;
} else if (!newRegistration) {
event.attendees++;
}
});

ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content:
Text('Unable to update registration: $e'),
backgroundColor:
Colors.red.shade700,
),
);
}
}

// ==========================================================
// GOOGLE CALENDAR
// ==========================================================

Future<void> addToCalendar(
Event event,
) async {
try {
final startDate = DateTime.parse(
'${event.fromDate} '
'${_convertTo24Hour(event.fromTime)}',
);

final endDate = DateTime.parse(
'${event.toDate} '
'${_convertTo24Hour(event.toTime)}',
);

final String start = startDate
    .toUtc()
    .toIso8601String()
    .replaceAll(RegExp(r'[-:]'), '')
    .split('.')
    .first;

final String end = endDate
    .toUtc()
    .toIso8601String()
    .replaceAll(RegExp(r'[-:]'), '')
    .split('.')
    .first;

final String url =
'https://calendar.google.com/calendar/render'
'?action=TEMPLATE'
'&text=${Uri.encodeComponent(event.title)}'
'&dates=$start/$end'
'&details=${Uri.encodeComponent(event.description)}'
'&location=${Uri.encodeComponent(event.location)}';

final uri = Uri.parse(url);

if (!await launchUrl(
uri,
mode:
LaunchMode.externalApplication,
)) {
throw Exception(
'Could not open Google Calendar.',
);
}
} catch (e) {
ScaffoldMessenger.of(context)
    .showSnackBar(
const SnackBar(
content: Text(
'Unable to add event to calendar.',
),
),
);
}
}

// ==========================================================
// TIME CONVERTER
// ==========================================================

String _convertTo24Hour(
String time,
) {
final format =
time.trim().split(' ');

if (format.length < 2) {
return time;
}

final parts =
format[0].split(':');

int hour =
int.tryParse(parts[0]) ?? 0;

final minute =
parts.length > 1
? parts[1]
    : '00';

final period =
format[1].toUpperCase();

if (period == 'PM' &&
hour != 12) {
hour += 12;
}

if (period == 'AM' &&
hour == 12) {
hour = 0;
}

return '${hour.toString().padLeft(2, '0')}:'
'$minute:00';
}

// ==========================================================
// CATEGORY COLOR
// ==========================================================

List<Color> _categoryColors(
String category,
) {
switch (category.toLowerCase()) {
case 'service':
return const [
purple,
purpleLight,
];

case 'fellowship':
return const [
Color(0xFF0F766E),
Color(0xFF2DD4BF),
];

case 'outreach':
return const [
Color(0xFFEA580C),
Color(0xFFFB923C),
];

case 'conference':
return const [
Color(0xFF2563EB),
Color(0xFF60A5FA),
];

case 'special':
return const [
Color(0xFFD97706),
gold,
];

default:
return const [
purple,
purpleLight,
];
}
}

// ==========================================================
// CATEGORY ICON
// ==========================================================

IconData _categoryIcon(
String category,
) {
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

String _monthName(
String date,
) {
try {
final parsed =
DateTime.parse(date);

const months = [
'JAN',
'FEB',
'MAR',
'APR',
'MAY',
'JUN',
'JUL',
'AUG',
'SEP',
'OCT',
'NOV',
'DEC',
];

return months[
parsed.month - 1];
} catch (_) {
return '';
}
}

String _dayNumber(
String date,
) {
try {
final parsed =
DateTime.parse(date);

return parsed.day
    .toString()
    .padLeft(2, '0');
} catch (_) {
return '--';
}
}

// ==========================================================
// BUILD
// ==========================================================

@override
Widget build(
BuildContext context,
) {
return Scaffold(
body: Container(
width: double.infinity,
height: double.infinity,

// ====================================================
// AUTH / DASHBOARD CONSISTENT BACKGROUND
// ====================================================

decoration:
const BoxDecoration(
gradient:
LinearGradient(
colors: [
Color(0xFF4C087A),
Color(0xFF6A0DAD),
Color(0xFF8B5CF6),
Color(0xFFFFD700),
],
stops: [
0.0,
0.35,
0.70,
1.0,
],
begin:
Alignment.topLeft,
end:
Alignment.bottomRight,
),
),

child: SafeArea(
child: Column(
children: [
_buildTopBar(),

_buildCategoryFilters(),

Expanded(
child:
_buildEventsStream(),
),
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
padding:
const EdgeInsets.symmetric(
horizontal: 20,
vertical: 13,
),
decoration: BoxDecoration(
color:
Colors.white.withOpacity(
0.96,
),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(
0.14,
),
blurRadius: 18,
offset:
const Offset(0, 5),
),
],
),
child: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 1250,
),
child: Row(
children: [
// BACK BUTTON
_TopBarButton(
icon:
Icons.arrow_back_rounded,
onTap: widget.onBack,
),

const SizedBox(
width: 12,
),

// ICON
Container(
width: 44,
height: 44,
decoration:
BoxDecoration(
gradient:
const LinearGradient(
colors: [
purple,
purpleLight,
],
),
borderRadius:
BorderRadius.circular(
13,
),
boxShadow: [
BoxShadow(
color: purple
    .withOpacity(
0.25,
),
blurRadius: 10,
offset:
const Offset(
0,
4,
),
),
],
),
child: const Icon(
Icons.event_rounded,
color: Colors.white,
size: 23,
),
),

const SizedBox(
width: 12,
),

const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Events & Announcements',
style:
TextStyle(
fontSize: 19,
fontWeight:
FontWeight.w800,
color:
Color(
0xFF202124,
),
),
),
SizedBox(
height: 2,
),
Text(
'Discover upcoming church activities',
style:
TextStyle(
fontSize: 12,
color:
Color(
0xFF777777,
),
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
padding:
const EdgeInsets.symmetric(
vertical: 12,
),
child: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 1250,
),
child:
SingleChildScrollView(
scrollDirection:
Axis.horizontal,
padding:
const EdgeInsets.symmetric(
horizontal: 20,
),
child: Row(
children:
categories.map(
(category) {
final selected =
selectedCategory ==
category;

return Padding(
padding:
const EdgeInsets
    .only(
right: 9,
),
child:
GestureDetector(
onTap: () {
setState(() {
selectedCategory =
category;
});
},
child:
AnimatedContainer(
duration:
const Duration(
milliseconds:
220,
),
padding:
const EdgeInsets
    .symmetric(
horizontal:
15,
vertical: 9,
),
decoration:
BoxDecoration(
color: selected
? Colors.white
    : Colors.white
    .withOpacity(
0.16,
),
borderRadius:
BorderRadius
    .circular(
30,
),
border:
Border.all(
color: Colors
    .white
    .withOpacity(
selected
? 0.9
    : 0.25,
),
),
boxShadow:
selected
? [
BoxShadow(
color: Colors
    .black
    .withOpacity(
0.12,
),
blurRadius:
10,
offset:
const Offset(
0,
4,
),
),
]
    : null,
),
child: Row(
children: [
Icon(
category ==
'all'
? Icons
    .apps_rounded
    : _categoryIcon(
category,
),
size: 17,
color: selected
? purple
    : Colors
    .white,
),
const SizedBox(
width: 7,
),
Text(
category ==
'all'
? 'All Events'
    : _capitalize(
category,
),
style:
TextStyle(
color: selected
? purple
    : Colors
    .white,
fontSize: 12,
fontWeight:
FontWeight
    .w700,
),
),
],
),
),
),
);
},
).toList(),
),
),
),
),
);
}

// ==========================================================
// EVENTS STREAM
// ==========================================================

Widget _buildEventsStream() {
return StreamBuilder<
QuerySnapshot>(
stream: FirebaseFirestore
    .instance
    .collection('events')
    .orderBy('fromDate')
    .snapshots(),

builder: (
context,
snapshot,
) {
if (snapshot.hasError) {
return _buildErrorState(
snapshot.error.toString(),
);
}

if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child:
CircularProgressIndicator(
color: Colors.white,
),
);
}

final allEvents =
snapshot.data!.docs
    .map(
(doc) =>
Event.fromFirestore(
doc,
userId,
),
)
    .toList();

final filteredEvents =
selectedCategory == 'all'
? allEvents
    : allEvents
    .where(
(event) =>
event.category
    .toLowerCase() ==
selectedCategory
    .toLowerCase(),
)
    .toList();

if (filteredEvents.isEmpty) {
return _buildEmptyState();
}

return LayoutBuilder(
builder:
(context, constraints) {
final columns =
constraints.maxWidth >= 1000
? 3
    : 2;

return Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 1250,
),
child:
GridView.builder(
padding:
const EdgeInsets
    .fromLTRB(
20,
8,
20,
35,
),
itemCount:
filteredEvents.length,
gridDelegate:
SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount:
columns,
crossAxisSpacing:
16,
mainAxisSpacing:
16,
childAspectRatio:
columns == 3
? 0.86
    : 0.82,
),
itemBuilder:
(
context,
index,
) {
return _AnimatedEventCard(
index: index,
child:
_buildEventCard(
filteredEvents[
index],
),
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

Widget _buildEventCard(
Event event,
) {
final colors =
_categoryColors(
event.category,
);

final isFull =
event.maxAttendees != null &&
event.attendees >=
event.maxAttendees! &&
!event.isRegistered;

double progress = 0;

if (event.maxAttendees != null &&
event.maxAttendees! > 0) {
progress =
(event.attendees /
event.maxAttendees!)
    .clamp(0.0, 1.0);
}

return Container(
decoration:
BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(
24,
),
boxShadow: [
BoxShadow(
color: Colors.black
    .withOpacity(
0.13,
),
blurRadius: 22,
offset:
const Offset(0, 9),
),
],
),
clipBehavior:
Clip.antiAlias,
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// ==================================================
// CARD HEADER
// ==================================================

Container(
height: 116,
width: double.infinity,
decoration:
BoxDecoration(
gradient:
LinearGradient(
colors: colors,
begin:
Alignment.topLeft,
end:
Alignment.bottomRight,
),
),
child: Stack(
children: [
Positioned(
right: -30,
top: -35,
child: Container(
width: 130,
height: 130,
decoration:
BoxDecoration(
color: Colors.white
    .withOpacity(
0.08,
),
shape:
BoxShape.circle,
),
),
),

Positioned(
right: 25,
bottom: -45,
child: Container(
width: 90,
height: 90,
decoration:
BoxDecoration(
color: Colors.white
    .withOpacity(
0.06,
),
shape:
BoxShape.circle,
),
),
),

Padding(
padding:
const EdgeInsets
    .all(16),
child: Row(
children: [
// DATE TILE
Container(
width: 64,
height: 72,
decoration:
BoxDecoration(
color: Colors
    .white
    .withOpacity(
0.96,
),
borderRadius:
BorderRadius
    .circular(
17,
),
),
child: Column(
mainAxisAlignment:
MainAxisAlignment
    .center,
children: [
Text(
_monthName(
event
    .fromDate,
),
style:
TextStyle(
color:
colors.first,
fontSize:
11,
fontWeight:
FontWeight
    .w800,
),
),
const SizedBox(
height: 1,
),
Text(
_dayNumber(
event
    .fromDate,
),
style:
const TextStyle(
color:
Color(
0xFF202124,
),
fontSize:
25,
fontWeight:
FontWeight
    .w900,
),
),
],
),
),

const SizedBox(
width: 13,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
mainAxisAlignment:
MainAxisAlignment
    .center,
children: [
Container(
padding:
const EdgeInsets
    .symmetric(
horizontal:
9,
vertical: 5,
),
decoration:
BoxDecoration(
color: Colors
    .white
    .withOpacity(
0.17,
),
borderRadius:
BorderRadius
    .circular(
20,
),
),
child: Row(
mainAxisSize:
MainAxisSize
    .min,
children: [
Icon(
_categoryIcon(
event
    .category,
),
color: Colors
    .white,
size: 13,
),
const SizedBox(
width: 5,
),
Text(
_capitalize(
event
    .category,
),
style:
const TextStyle(
color: Colors
    .white,
fontSize:
10,
fontWeight:
FontWeight
    .w700,
),
),
],
),
),

const SizedBox(
height: 8,
),

Text(
event.title,
maxLines: 2,
overflow:
TextOverflow
    .ellipsis,
style:
const TextStyle(
color:
Colors.white,
fontSize:
18,
fontWeight:
FontWeight
    .w800,
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

// ==================================================
// CARD BODY
// ==================================================

Expanded(
child: Padding(
padding:
const EdgeInsets
    .fromLTRB(
16,
14,
16,
14,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// DESCRIPTION
Text(
event.description,
maxLines: 2,
overflow:
TextOverflow.ellipsis,
style:
const TextStyle(
color:
Color(0xFF666666),
fontSize: 12,
height: 1.45,
),
),

const SizedBox(
height: 13,
),

// TIME
_InfoRow(
icon:
Icons.access_time_rounded,
title: 'Time',
value:
'${event.fromTime} – ${event.toTime}',
color:
colors.first,
),

const SizedBox(
height: 8,
),

// LOCATION
_InfoRow(
icon:
Icons.location_on_rounded,
title: 'Location',
value:
event.location.isEmpty
? 'Not specified'
    : event.location,
color:
colors.first,
),

const SizedBox(
height: 12,
),

// ATTENDEES
Row(
children: [
Container(
width: 34,
height: 34,
decoration:
BoxDecoration(
color: colors.first
    .withOpacity(
0.08,
),
borderRadius:
BorderRadius
    .circular(
10,
),
),
child: Icon(
Icons
    .people_alt_rounded,
color:
colors.first,
size: 17,
),
),

const SizedBox(
width: 9,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
Text(
event.maxAttendees !=
null
? '${event.attendees} / ${event.maxAttendees} attendees'
    : '${event.attendees} attendees',
style:
const TextStyle(
color:
Color(
0xFF303030,
),
fontSize:
11,
fontWeight:
FontWeight
    .w700,
),
),

if (event
    .maxAttendees !=
null)
const SizedBox(
height: 5,
),

if (event
    .maxAttendees !=
null)
ClipRRect(
borderRadius:
BorderRadius
    .circular(
5,
),
child:
LinearProgressIndicator(
value:
progress,
minHeight:
5,
backgroundColor:
const Color(
0xFFEDEDED,
),
valueColor:
AlwaysStoppedAnimation<
Color>(
colors.first,
),
),
),
],
),
),
],
),

const Spacer(),

// ==================================================
// ACTIONS
// ==================================================

Row(
children: [
Expanded(
child:
OutlinedButton.icon(
onPressed:
() =>
addToCalendar(
event,
),
icon:
const Icon(
Icons
    .calendar_month_rounded,
size: 17,
),
label:
const Text(
'Calendar',
),
style:
OutlinedButton
    .styleFrom(
foregroundColor:
colors.first,
side:
BorderSide(
color: colors
    .first
    .withOpacity(
0.35,
),
),
padding:
const EdgeInsets
    .symmetric(
vertical: 11,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
12,
),
),
),
),
),

const SizedBox(
width: 8,
),

Expanded(
child:
ElevatedButton(
onPressed:
isFull
? null
    : () =>
toggleRegister(
event,
),
style:
ElevatedButton
    .styleFrom(
backgroundColor:
event.isRegistered
? Colors
    .red
    .shade600
    : colors.first,
foregroundColor:
Colors.white,
disabledBackgroundColor:
Colors.grey
    .shade300,
disabledForegroundColor:
Colors.grey
    .shade600,
elevation: 0,
padding:
const EdgeInsets
    .symmetric(
vertical: 11,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
12,
),
),
),
child: Text(
event.isRegistered
? 'Unregister'
    : isFull
? 'Full'
    : 'Register',
style:
const TextStyle(
fontSize:
12,
fontWeight:
FontWeight
    .w800,
),
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
);
}

// ==========================================================
// EMPTY STATE
// ==========================================================

Widget _buildEmptyState() {
return Center(
child: Container(
margin:
const EdgeInsets.all(25),
padding:
const EdgeInsets.all(30),
decoration:
BoxDecoration(
color:
Colors.white.withOpacity(
0.96,
),
borderRadius:
BorderRadius.circular(
24,
),
),
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
Container(
width: 72,
height: 72,
decoration:
BoxDecoration(
color: purple
    .withOpacity(
0.08,
),
shape:
BoxShape.circle,
),
child: const Icon(
Icons
    .event_busy_rounded,
size: 34,
color: purple,
),
),
const SizedBox(
height: 15,
),
const Text(
'No Events Found',
style:
TextStyle(
fontSize: 19,
fontWeight:
FontWeight.w800,
),
),
const SizedBox(
height: 6,
),
Text(
'There are no events in this category.',
textAlign:
TextAlign.center,
style:
TextStyle(
color:
Colors.grey.shade600,
fontSize: 13,
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

Widget _buildErrorState(
String error,
) {
return Center(
child: Container(
margin:
const EdgeInsets.all(25),
padding:
const EdgeInsets.all(25),
decoration:
BoxDecoration(
color:
Colors.white.withOpacity(
0.96,
),
borderRadius:
BorderRadius.circular(
20,
),
),
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
const Icon(
Icons.error_outline_rounded,
color:
Colors.red,
size: 45,
),
const SizedBox(
height: 12,
),
const Text(
'Unable to load events',
style:
TextStyle(
fontSize: 17,
fontWeight:
FontWeight.w800,
),
),
const SizedBox(
height: 6,
),
Text(
error,
textAlign:
TextAlign.center,
style:
TextStyle(
color:
Colors.grey.shade600,
fontSize: 12,
),
),
],
),
),
);
}

// ==========================================================
// CAPITALIZE
// ==========================================================

String _capitalize(
String value,
) {
if (value.isEmpty) {
return value;
}

return value[0].toUpperCase() +
value.substring(1);
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
Widget build(
BuildContext context,
) {
return Row(
children: [
Container(
width: 34,
height: 34,
decoration:
BoxDecoration(
color: color.withOpacity(
0.08,
),
borderRadius:
BorderRadius.circular(
10,
),
),
child: Icon(
icon,
color: color,
size: 17,
),
),
const SizedBox(
width: 9,
),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style:
const TextStyle(
fontSize: 9,
color:
Color(0xFF999999),
fontWeight:
FontWeight.w600,
),
),
const SizedBox(
height: 1,
),
Text(
value,
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style:
const TextStyle(
fontSize: 11,
color:
Color(0xFF333333),
fontWeight:
FontWeight.w700,
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

class _TopBarButton
extends StatelessWidget {
final IconData icon;
final VoidCallback onTap;

const _TopBarButton({
required this.icon,
required this.onTap,
});

@override
Widget build(
BuildContext context,
) {
return Material(
color: Colors.transparent,
child: InkWell(
onTap: onTap,
borderRadius:
BorderRadius.circular(
13,
),
child: Container(
width: 43,
height: 43,
decoration:
BoxDecoration(
color:
const Color(0xFFF4ECFA),
borderRadius:
BorderRadius.circular(
13,
),
border: Border.all(
color: purple.withOpacity(
0.08,
),
),
),
child: Icon(
icon,
color: purple,
size: 21,
),
),
),
);
}
}

// ============================================================
// EVENT CARD ANIMATION
// ============================================================

class _AnimatedEventCard
extends StatefulWidget {
final Widget child;
final int index;

const _AnimatedEventCard({
required this.child,
required this.index,
});

@override
State<_AnimatedEventCard> createState() =>
_AnimatedEventCardState();
}

class _AnimatedEventCardState
extends State<_AnimatedEventCard>
with SingleTickerProviderStateMixin {
late AnimationController
_controller;

late Animation<double>
_fadeAnimation;

late Animation<Offset>
_slideAnimation;

@override
void initState() {
super.initState();

_controller =
AnimationController(
vsync: this,
duration: Duration(
milliseconds:
450 + (widget.index * 70),
),
);

_fadeAnimation =
CurvedAnimation(
parent: _controller,
curve: Curves.easeOut,
);

_slideAnimation =
Tween<Offset>(
begin:
const Offset(0, 0.08),
end: Offset.zero,
).animate(
CurvedAnimation(
parent: _controller,
curve:
Curves.easeOutCubic,
),
);

Future.delayed(
Duration(
milliseconds:
widget.index * 60,
),
() {
if (mounted) {
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
Widget build(
BuildContext context,
) {
return FadeTransition(
opacity: _fadeAnimation,
child: SlideTransition(
position:
_slideAnimation,
child: widget.child,
),
);
}
}
