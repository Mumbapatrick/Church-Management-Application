// send_message_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/message.dart';

class SendMessageScreen extends StatefulWidget {
  final VoidCallback onBack;
  const SendMessageScreen({super.key, required this.onBack});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String selectedCategory = 'announcement';
  bool isImportant = false;
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);

      final message = Message(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        author: 'Admin', // TODO: Replace with FirebaseAuth user later
        category: selectedCategory,
        timestamp: DateTime.now(),
        isRead: false,
        isImportant: isImportant,
      );

      await FirebaseFirestore.instance.collection('messages').add(message.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Message sent successfully!')),
      );

      // Reset form
      _titleController.clear();
      _contentController.clear();
      setState(() {
        isImportant = false;
        _isSending = false;
      });

      widget.onBack();
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Message"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        backgroundColor: Colors.purple,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Message Title *', Icons.title),
                validator: (value) => value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Content field
              TextFormField(
                controller: _contentController,
                decoration: _inputDecoration('Message Content *', Icons.message),
                maxLines: 6,
                validator: (value) => value!.isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 20),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['announcement', 'devotional', 'prayer', 'newsletter']
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: _inputDecoration('Category', Icons.category),
              ),
              const SizedBox(height: 10),

              // Important checkbox
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  value: isImportant,
                  title: const Text('Mark as Important'),
                  secondary: const Icon(Icons.star, color: Colors.red),
                  onChanged: (val) => setState(() => isImportant = val ?? false),
                ),
              ),
              const SizedBox(height: 30),

              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSending
                      ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


