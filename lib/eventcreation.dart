import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CreateEventScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  final TextEditingController _locationController =
  TextEditingController();

  final TextEditingController _fromDateController =
  TextEditingController();

  final TextEditingController _fromTimeController =
  TextEditingController();

  final TextEditingController _toDateController =
  TextEditingController();

  final TextEditingController _toTimeController =
  TextEditingController();

  final TextEditingController _maxAttendeesController =
  TextEditingController();

  TimeOfDay? _fromTimeOfDay;
  TimeOfDay? _toTimeOfDay;

  DateTime? _fromDate;
  DateTime? _toDate;

  String category = 'service';

  final List<String> categories = [
    'service',
    'conference',
    'outreach',
    'fellowship',
    'special',
  ];

  bool _isSaving = false;

  // ==========================================================
  // THEME
  // ==========================================================

  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color lightPurpleAccent = Color(0xFFA78BFA);
  static const Color deepBgGradientStart = Color(0xFF2E1065);
  static const Color deepBgGradientEnd = Color(0xFF4C1D95);

  static const Color cardBgStart = Color(0xFFFFFDF8);
  static const Color cardBgEnd = Color(0xFFFAF5E8);
  static const Color sacredGold = Color(0xFFD97706);
  static const Color sacredGoldDark = Color(0xFFB45309);

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _fromDateController.dispose();
    _fromTimeController.dispose();
    _toDateController.dispose();
    _toTimeController.dispose();
    _maxAttendeesController.dispose();

    super.dispose();
  }

  // ==========================================================
  // USER FEEDBACK
  // ==========================================================

  void _showMessage(
      String message, {
        bool success = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? Colors.green.shade700
              : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ==========================================================
  // DATE FORMATTING
  // ==========================================================

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  DateTime? get _startDateTime {
    if (_fromDate == null || _fromTimeOfDay == null) {
      return null;
    }

    return DateTime(
      _fromDate!.year,
      _fromDate!.month,
      _fromDate!.day,
      _fromTimeOfDay!.hour,
      _fromTimeOfDay!.minute,
    );
  }

  DateTime? get _endDateTime {
    if (_toDate == null || _toTimeOfDay == null) {
      return null;
    }

    return DateTime(
      _toDate!.year,
      _toDate!.month,
      _toDate!.day,
      _toTimeOfDay!.hour,
      _toTimeOfDay!.minute,
    );
  }

  // ==========================================================
  // DATE PICKER
  // ==========================================================

  Future<void> _pickDate(
      TextEditingController controller,
      bool isStart,
      ) async {
    if (_isSaving) return;

    final now = DateTime.now();

    final initialDate = isStart
        ? (_fromDate ?? now)
        : (_toDate ?? _fromDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) &&
          isStart
          ? now
          : initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Select event start date' : 'Select event end date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryPurple,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1B4B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _fromDate = picked;
        _fromDateController.text = _formatDate(picked);

        // Keep end date sensible when start date changes.
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
          _toDateController.text = _formatDate(picked);
        }
      } else {
        _toDate = picked;
        _toDateController.text = _formatDate(picked);
      }
    });

    _formKey.currentState?.validate();
  }

  // ==========================================================
  // TIME PICKER
  // ==========================================================

  Future<void> _pickTime(
      TextEditingController controller,
      bool isStart,
      ) async {
    if (_isSaving) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_fromTimeOfDay ?? TimeOfDay.now())
          : (_toTimeOfDay ?? TimeOfDay.now()),
      helpText: isStart ? 'Select start time' : 'Select end time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryPurple,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1B4B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _fromTimeOfDay = picked;
        _fromTimeController.text = _formatTime(picked);
      } else {
        _toTimeOfDay = picked;
        _toTimeController.text = _formatTime(picked);
      }
    });

    _formKey.currentState?.validate();
  }

  // ==========================================================
  // DATE AND TIME VALIDATION
  // ==========================================================

  String? _validateStartDateTime() {
    final start = _startDateTime;

    if (start == null) {
      return 'Please select the event start date and time.';
    }

    if (start.isBefore(DateTime.now())) {
      return 'The event start date and time cannot be in the past.';
    }

    return null;
  }

  String? _validateEndDateTime() {
    final end = _endDateTime;
    final start = _startDateTime;

    if (end == null) {
      return 'Please select the event end date and time.';
    }

    if (start != null && !end.isAfter(start)) {
      return 'End date and time must be after the start.';
    }

    return null;
  }

  String? _validateCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid whole number.';
    }

    if (number <= 0) {
      return 'Maximum attendees must be greater than zero.';
    }

    return null;
  }

  // ==========================================================
  // SAVE EVENT
  // ==========================================================

  Future<void> _saveEvent() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showMessage(
        'Please correct the highlighted fields before continuing.',
      );
      return;
    }

    final startDateTime = _startDateTime;
    final endDateTime = _endDateTime;

    if (startDateTime == null || endDateTime == null) {
      _showMessage('Please select the event date and time.');
      return;
    }

    if (!endDateTime.isAfter(startDateTime)) {
      _showMessage(
        'The event end date and time must be after the start.',
      );
      return;
    }

    final capacityText = _maxAttendeesController.text.trim();

    final int? maxAttendees = capacityText.isEmpty
        ? null
        : int.tryParse(capacityText);

    if (capacityText.isNotEmpty &&
        (maxAttendees == null || maxAttendees <= 0)) {
      _showMessage('Please enter a valid maximum attendee number.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final eventData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),

        // Display-friendly date fields.
        'fromDate': _formatDate(startDateTime),
        'fromTime': _formatTime(_fromTimeOfDay!),
        'toDate': _formatDate(endDateTime),
        'toTime': _formatTime(_toTimeOfDay!),

        // Timestamp fields for reliable date calculations.
        'startAt': Timestamp.fromDate(startDateTime),
        'endAt': Timestamp.fromDate(endDateTime),

        'category': category.toLowerCase(),
        'attendees': 0,
        'maxAttendees': maxAttendees,

        // Registration map used by EventsPage.
        'registrations': <String, dynamic>{},

        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('events')
          .add(eventData);

      if (!mounted) return;

      _showMessage(
        'Event created successfully!',
        success: true,
      );

      // Return to the previous page after a successful save.
      widget.onBack();
    } on FirebaseException catch (e) {
      debugPrint('Firebase event creation error: ${e.code} ${e.message}');

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
          'You do not have permission to create events. Please contact the administrator.';
          break;

        case 'unavailable':
        case 'network-request-failed':
          message =
          'Unable to connect. Please check your internet connection and try again.';
          break;

        case 'deadline-exceeded':
          message =
          'The request took too long. Please check your connection and try again.';
          break;

        default:
          message =
          'We could not save the event. Please try again.';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint('Event creation error: $e');

      if (!mounted) return;

      _showMessage(
        'Something went wrong while creating the event. '
            'Your entered information is still available. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _buildInputDecoration(
      String label,
      IconData icon, {
        String? hint,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: sacredGoldDark.withOpacity(0.85),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
      ),
      prefixIcon: Icon(
        icon,
        color: sacredGoldDark,
        size: 20,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: sacredGold.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: sacredGold.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryPurple,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  // ==========================================================
  // SECTION HEADING
  // ==========================================================

  Widget _sectionHeading(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryPurple,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF311242),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DATE/TIME FIELD
  // ==========================================================

  Widget _dateTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: _isSaving ? null : onTap,
      style: const TextStyle(
        color: Color(0xFF1E1B4B),
        fontWeight: FontWeight.w600,
      ),
      decoration: _buildInputDecoration(label, icon).copyWith(
        suffixIcon: const Icon(
          Icons.arrow_drop_down_rounded,
          color: primaryPurple,
        ),
      ),
      validator: validator,
    );
  }

  // ==========================================================
  // RESPONSIVE FIELD ROW
  // ==========================================================

  Widget _responsiveFields(
      BuildContext context,
      Widget first,
      Widget second,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              first,
              const SizedBox(height: 15),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 13),
            Expanded(child: second),
          ],
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
      extendBodyBehindAppBar: true,
      backgroundColor: deepBgGradientStart,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Go back',
          icon: const Icon(
            Icons.arrow_back,
            color: cardBgStart,
          ),
          onPressed: _isSaving ? null : widget.onBack,
        ),
        title: const Text(
          'CREATE NEW EVENT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cardBgStart,
            letterSpacing: 1.2,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deepBgGradientStart,
              deepBgGradientEnd,
              Color(0xFF1E1B4B),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 850,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(
                        constraints.maxWidth < 450 ? 16 : 25,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cardBgStart,
                            cardBgEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: sacredGold.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: sacredGold.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // INTRODUCTION

                            const Text(
                              'Create a Church Event',
                              style: TextStyle(
                                color: Color(0xFF311242),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Provide the event details to publish '
                                  'the schedule to church members.',
                              style: TextStyle(
                                color: const Color(0xFF311242)
                                    .withOpacity(0.75),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 25),

                            // EVENT INFORMATION

                            _sectionHeading(
                              'Event Information',
                              'Enter the main details of your event.',
                              Icons.event_note_rounded,
                            ),

                            TextFormField(
                              controller: _titleController,
                              enabled: !_isSaving,
                              textCapitalization:
                              TextCapitalization.sentences,
                              maxLength: 100,
                              style: const TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                'Event Title *',
                                Icons.event_note,
                                hint: 'e.g. Sunday Worship Service',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter the event title.';
                                }

                                if (value.trim().length < 3) {
                                  return 'Title must contain at least 3 characters.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _descriptionController,
                              enabled: !_isSaving,
                              textCapitalization:
                              TextCapitalization.sentences,
                              maxLines: 4,
                              maxLength: 1000,
                              style: const TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                'Event Description *',
                                Icons.description_outlined,
                                hint: 'Describe the event...',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter an event description.';
                                }

                                if (value.trim().length < 5) {
                                  return 'Description is too short.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _locationController,
                              enabled: !_isSaving,
                              textCapitalization:
                              TextCapitalization.words,
                              style: const TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                'Event Location *',
                                Icons.location_on_outlined,
                                hint: 'e.g. Word & Prayer Church',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter the event location.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 25),

                            // EVENT SCHEDULE

                            _sectionHeading(
                              'Event Schedule',
                              'Choose when the event starts and ends.',
                              Icons.calendar_month_rounded,
                            ),

                            _responsiveFields(
                              context,
                              _dateTimeField(
                                controller: _fromDateController,
                                label: 'Start Date *',
                                icon: Icons.calendar_today_outlined,
                                onTap: () => _pickDate(
                                  _fromDateController,
                                  true,
                                ),
                                validator: (_) {
                                  if (_fromDate == null) {
                                    return 'Select start date.';
                                  }

                                  return _validateStartDateTime();
                                },
                              ),
                              _dateTimeField(
                                controller: _fromTimeController,
                                label: 'Start Time *',
                                icon: Icons.access_time,
                                onTap: () => _pickTime(
                                  _fromTimeController,
                                  true,
                                ),
                                validator: (_) {
                                  if (_fromTimeOfDay == null) {
                                    return 'Select start time.';
                                  }

                                  return _validateStartDateTime();
                                },
                              ),
                            ),

                            const SizedBox(height: 15),

                            _responsiveFields(
                              context,
                              _dateTimeField(
                                controller: _toDateController,
                                label: 'End Date *',
                                icon: Icons.calendar_today,
                                onTap: () => _pickDate(
                                  _toDateController,
                                  false,
                                ),
                                validator: (_) {
                                  if (_toDate == null) {
                                    return 'Select end date.';
                                  }

                                  return _validateEndDateTime();
                                },
                              ),
                              _dateTimeField(
                                controller: _toTimeController,
                                label: 'End Time *',
                                icon: Icons.access_time_filled,
                                onTap: () => _pickTime(
                                  _toTimeController,
                                  false,
                                ),
                                validator: (_) {
                                  if (_toTimeOfDay == null) {
                                    return 'Select end time.';
                                  }

                                  return _validateEndDateTime();
                                },
                              ),
                            ),

                            const SizedBox(height: 25),

                            // CATEGORY AND CAPACITY

                            _sectionHeading(
                              'Event Settings',
                              'Choose the event category and capacity.',
                              Icons.settings_outlined,
                            ),

                            DropdownButtonFormField<String>(
                              value: category,
                              isExpanded: true,
                              dropdownColor: cardBgStart,
                              decoration: _buildInputDecoration(
                                'Event Category *',
                                Icons.category_outlined,
                              ),
                              items: categories.map((value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF1E1B4B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                if (value != null) {
                                  setState(() => category = value);
                                }
                              },
                            ),

                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _maxAttendeesController,
                              enabled: !_isSaving,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                'Maximum Attendees (Optional)',
                                Icons.groups_outlined,
                                hint: 'Leave blank for unlimited attendance',
                              ),
                              validator: _validateCapacity,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Leave the maximum attendees field blank '
                                  'if the event has no registration limit.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // ACTION BUTTONS

                            LayoutBuilder(
                              builder: (context, buttonConstraints) {
                                final stackButtons =
                                    buttonConstraints.maxWidth < 420;

                                final createButton =
                                SizedBox(
                                  height: 50,
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                    _isSaving ? null : _saveEvent,
                                    icon: _isSaving
                                        ? const SizedBox(
                                      height: 19,
                                      width: 19,
                                      child:
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Icon(
                                      Icons.check_circle_outline,
                                      size: 19,
                                    ),
                                    label: Text(
                                      _isSaving
                                          ? 'SAVING EVENT...'
                                          : 'CREATE EVENT',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryPurple,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                      Colors.grey.shade400,
                                      elevation: 4,
                                      shadowColor:
                                      primaryPurple.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                );

                                final cancelButton =
                                SizedBox(
                                  height: 50,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed:
                                    _isSaving ? null : widget.onBack,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                      const Color(0xFF4C1D95),
                                      side: BorderSide(
                                        color: primaryPurple.withOpacity(0.4),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'CANCEL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );

                                if (stackButtons) {
                                  return Column(
                                    children: [
                                      createButton,
                                      const SizedBox(height: 12),
                                      cancelButton,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: createButton),
                                    const SizedBox(width: 12),
                                    Expanded(child: cancelButton),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 14),

                            Center(
                              child: Text(
                                'Please review all event details before publishing.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}