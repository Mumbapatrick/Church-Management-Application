import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Brand Color Palette
const Color purplePrimary = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color inputBg = Color(0xFFF8F9FA);
const Color textDark = Color(0xFF1E293B);
const Color textGrey = Color(0xFF64748B);

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
  final VoidCallback? onBack;

  const MeetingScheduler({super.key, this.onBack});

  @override
  State<MeetingScheduler> createState() => _MeetingSchedulerState();
}

class _MeetingSchedulerState extends State<MeetingScheduler> {
  int _selectedTabIndex = 0; // 0 for "Schedule Meeting", 1 for "My Meetings"

  String? selectedDate;
  String? selectedTime;
  String duration = '60';
  String? selectedPurpose;

  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    descriptionController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Date parser helper for "My Meetings" card header
  Map<String, String> _parseDateString(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      return {
        'month': months[parsed.month - 1],
        'day': parsed.day.toString().padLeft(2, '0'),
      };
    } catch (_) {
      return {'month': 'DATE', 'day': rawDate};
    }
  }

  // Schedule Meeting Logic
  void handleSchedule() async {
    if (selectedDate == null ||
        selectedTime == null ||
        selectedPurpose == null ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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

    try {
      await FirebaseFirestore.instance
          .collection('meetings')
          .add(meeting.toMap());

      final docRef = FirebaseFirestore.instance
          .collection('availability')
          .doc(meeting.date);

      final doc = await docRef.get();
      if (doc.exists) {
        List<dynamic> slots = doc['availableSlots'] ?? [];
        slots.remove(meeting.time);
        await docRef.update({'availableSlots': slots});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Meeting request submitted! Await approval."),
          backgroundColor: purplePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        selectedDate = null;
        selectedTime = null;
        duration = '60';
        selectedPurpose = null;
        descriptionController.clear();
        phoneController.clear();
        emailController.clear();
        _isSubmitting = false;
        _selectedTabIndex = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to schedule: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [purpleDark, purplePrimary, purpleLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              const SizedBox(height: 8),
              _buildCustomTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildScheduleForm()
                    : _buildMyMeetingsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar with High-Visibility Back Button
  Widget _buildTopHeader() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onBack ?? () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: purplePrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pastoral Meetings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Book counseling, prayer, or guidance sessions",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom Pill Tab Bar
  Widget _buildCustomTabBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Schedule Meeting",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _selectedTabIndex == 0 ? purplePrimary : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  "My Meetings",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _selectedTabIndex == 1 ? purplePrimary : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Centered Schedule Form Tab
  Widget _buildScheduleForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Select Date", isRequired: true),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('availability')
                      .orderBy('date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator(color: purplePrimary);
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "No available dates set by admin.",
                        style: TextStyle(color: textGrey, fontSize: 12),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    final dates = docs.map((d) => d.id).toList();

                    return _buildCustomDropdown(
                      value: selectedDate,
                      hintText: "Choose date",
                      icon: Icons.calendar_today_outlined,
                      items: dates,
                      onChanged: (value) {
                        setState(() {
                          selectedDate = value;
                          selectedTime = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 18),

                if (selectedDate != null) ...[
                  _buildFieldLabel("Select Time", isRequired: true),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('availability')
                        .doc(selectedDate)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator(color: purplePrimary);
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          "No available slots for this date.",
                          style: TextStyle(color: textGrey, fontSize: 12),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      List<String> slots = List<String>.from(data['availableSlots'] ?? []);
                      slots = slots.toSet().toList();

                      if (slots.isEmpty) {
                        return const Text(
                          "No available slots for this date.",
                          style: TextStyle(color: textGrey, fontSize: 12),
                        );
                      }

                      if (selectedTime != null && !slots.contains(selectedTime)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => selectedTime = null);
                        });
                      }

                      return _buildCustomDropdown(
                        value: selectedTime,
                        hintText: "Select slot time",
                        icon: Icons.access_time_rounded,
                        items: slots,
                        onChanged: (value) => setState(() => selectedTime = value),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                _buildFieldLabel("Duration"),
                _buildCustomDropdown(
                  value: duration,
                  hintText: "60 min",
                  icon: Icons.timer_outlined,
                  items: ['30', '60', '90'],
                  itemFormatter: (val) => "$val min",
                  onChanged: (value) => setState(() => duration = value!),
                ),
                const SizedBox(height: 18),

                _buildFieldLabel("Purpose / Reason", isRequired: true),
                _buildCustomDropdown(
                  value: selectedPurpose,
                  hintText: "Select Purpose",
                  icon: Icons.psychology_outlined,
                  items: const [
                    'Counseling',
                    'Prayer',
                    'Deliverance Cases',
                    'Mentorship / Guidance',
                    'Bible Study / Spiritual Growth',
                    'Leadership Training',
                    'Conflict Resolution / Mediation',
                    'Youth Fellowship',
                    'Marriage & Family Support',
                    'Career / Academic Guidance',
                    'Financial Guidance'
                  ],
                  onChanged: (value) => setState(() => selectedPurpose = value),
                ),
                const SizedBox(height: 18),

                _buildFieldLabel("Phone Number", isRequired: true),
                _buildTextField(
                  controller: phoneController,
                  hintText: "07XXXXXXXX / 01XXXXXXXX",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),

                _buildFieldLabel("Email Address (Optional)"),
                _buildTextField(
                  controller: emailController,
                  hintText: "example@email.com",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),

                _buildFieldLabel("Additional Details (Optional)"),
                _buildTextField(
                  controller: descriptionController,
                  hintText: "Provide context or notes...",
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : handleSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purplePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Submit Request",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Responsive Grid for "My Meetings"
  Widget _buildMyMeetingsView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width >= 900 ? 3 : 2;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('meetings')
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "No meetings found.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final meetings =
            snapshot.data!.docs.map((doc) => Meeting.fromDoc(doc)).toList();

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 280,
                  ),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    final dateParts = _parseDateString(meeting.date);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6A0DAD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dateParts['month']!,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: textGrey,
                                        ),
                                      ),
                                      Text(
                                        dateParts['day']!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: textDark,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${meeting.duration} min session",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        meeting.purpose,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Card Body Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (meeting.description.isNotEmpty) ...[
                                    Text(
                                      meeting.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 16, color: purplePrimary),
                                      const SizedBox(width: 6),
                                      Text(
                                        meeting.time,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 16, color: purplePrimary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          meeting.memberPhone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: textDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Status",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textGrey,
                                        ),
                                      ),
                                      _buildStyledStatusBadge(meeting.status),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  // Status Badge Builder
  Widget _buildStyledStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF4338CA);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'confirmed':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        icon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        icon = Icons.cancel_outlined;
        break;
      case 'pending':
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // Field Label Builder
  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Custom Dropdown Builder
  Widget _buildCustomDropdown<T>({
    required T? value,
    required String hintText,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemFormatter,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: textGrey),
              const SizedBox(width: 10),
              Text(hintText, style: const TextStyle(color: textGrey, fontSize: 14)),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
          items: items.map((item) {
            final displayText = itemFormatter != null ? itemFormatter(item) : item.toString();
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: purplePrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Custom TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: textGrey, fontSize: 14, fontWeight: FontWeight.normal),
          icon: Icon(icon, color: textGrey, size: 20),
        ),
      ),
    );
  }
}