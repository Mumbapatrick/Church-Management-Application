import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventScreen extends StatefulWidget {
  final VoidCallback onBack;
  const CreateEventScreen({super.key, required this.onBack});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _fromTimeController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _toTimeController = TextEditingController();
  final TextEditingController _maxAttendeesController = TextEditingController();

  // Internal TimeOfDay objects to build accurate DateTime values
  TimeOfDay? _fromTimeOfDay;
  TimeOfDay? _toTimeOfDay;

  String category = 'service';
  final List<String> categories = [
    'service',
    'conference',
    'outreach',
    'fellowship',
    'special'
  ];

  bool _isSaving = false;

  // 🔹 Color Theme Tokens
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color lightPurpleAccent = Color(0xFFA78BFA);
  static const Color deepBgGradientStart = Color(0xFF2E1065);
  static const Color deepBgGradientEnd = Color(0xFF4C1D95);

  static const Color cardBgStart = Color(0xFFFFFDF8);
  static const Color cardBgEnd = Color(0xFFFAF5E8);
  static const Color sacredGold = Color(0xFFD97706);
  static const Color sacredGoldDark = Color(0xFFB45309);

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

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse ISO dates (yyyy-MM-dd)
      final DateTime startDate = DateTime.parse(_fromDateController.text);
      final DateTime endDate = DateTime.parse(_toDateController.text);

      // Combine Date + Selected TimeOfDay into complete DateTime instances
      final DateTime startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        _fromTimeOfDay?.hour ?? 0,
        _fromTimeOfDay?.minute ?? 0,
      );

      final DateTime endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        _toTimeOfDay?.hour ?? 23,
        _toTimeOfDay?.minute ?? 59,
      );

      // Save Timestamps directly to Firestore
      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'startAt': Timestamp.fromDate(startDateTime),
        'endAt': Timestamp.fromDate(endDateTime),
        'category': category,
        'attendees': 0,
        'maxAttendees': int.tryParse(_maxAttendeesController.text),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1B4B),
          content: Text(
            '✅ Event created successfully!',
            style: TextStyle(
              fontFamily: 'serif',
              color: cardBgStart,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      widget.onBack();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            '⚠️ Failed to create event: $e',
            style: const TextStyle(
              fontFamily: 'serif',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _pickTime(TextEditingController controller, bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    if (picked != null) {
      if (isStart) {
        _fromTimeOfDay = picked;
      } else {
        _toTimeOfDay = picked;
      }

      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final hourStr = hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      controller.text = '$hourStr:$minuteStr $period';
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'serif',
        color: sacredGoldDark.withOpacity(0.85),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: sacredGoldDark, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: deepBgGradientStart,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cardBgStart),
          onPressed: widget.onBack,
        ),
        title: const Text(
          "CREATE NEW EVENT",
          style: TextStyle(
            fontFamily: 'serif',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cardBgStart, cardBgEnd],
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
                    Text(
                      "Provide event details to publish schedule to all members.",
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: const Color(0xFF311242).withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _buildInputDecoration(
                          'Event Title *', Icons.event_note),
                      validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _buildInputDecoration(
                          'Description *', Icons.description_outlined),
                      validator: (value) =>
                      value!.isEmpty ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _buildInputDecoration(
                          'Location *', Icons.location_on_outlined),
                      validator: (value) =>
                      value!.isEmpty ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fromDateController,
                            readOnly: true,
                            style: const TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration(
                                'From Date *', Icons.calendar_today_outlined),
                            onTap: () => _pickDate(_fromDateController),
                            validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fromTimeController,
                            readOnly: true,
                            style: const TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration(
                                'From Time *', Icons.access_time),
                            onTap: () => _pickTime(_fromTimeController, true),
                            validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _toDateController,
                            readOnly: true,
                            style: const TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration(
                                'To Date *', Icons.calendar_today),
                            onTap: () => _pickDate(_toDateController),
                            validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _toTimeController,
                            readOnly: true,
                            style: const TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDecoration(
                                'To Time *', Icons.access_time_filled),
                            onTap: () => _pickTime(_toTimeController, false),
                            validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      dropdownColor: cardBgStart,
                      decoration: _buildInputDecoration(
                          'Category *', Icons.category_outlined),
                      value: category,
                      items: categories
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => category = val!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _maxAttendeesController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _buildInputDecoration(
                          'Max Attendees (Optional)', Icons.groups_outlined),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: primaryPurple.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveEvent,
                            icon: _isSaving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: _isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'CREATE EVENT',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4C1D95),
                              side: BorderSide(
                                color: primaryPurple.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: widget.onBack,
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 13,
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
          ),
        ),
      ),
    );
  }
}