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

  String category = 'service';
  final List<String> categories = ['service', 'conference', 'outreach', 'fellowship', 'special'];

  bool _isSaving = false;

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'fromDate': _fromDateController.text,
        'fromTime': _fromTimeController.text,
        'toDate': _toDateController.text,
        'toTime': _toTimeController.text,
        'category': category,
        'attendees': 0,
        'maxAttendees': int.tryParse(_maxAttendeesController.text),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      controller.text = '$hour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Event"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title *'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description *'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location *'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // From Date & Time
              TextFormField(
                controller: _fromDateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'From Date *'),
                onTap: () => _pickDate(_fromDateController),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fromTimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'From Time *'),
                onTap: () => _pickTime(_fromTimeController),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // To Date & Time
              TextFormField(
                controller: _toDateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'To Date *'),
                onTap: () => _pickDate(_toDateController),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _toTimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'To Time *'),
                onTap: () => _pickTime(_toTimeController),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category *'),
                value: category,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => category = val!),
              ),
              const SizedBox(height: 16),

              // Max Attendees
              TextFormField(
                controller: _maxAttendeesController,
                decoration: const InputDecoration(labelText: 'Max Attendees (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEvent,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
