import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/message.dart';

class MessagesScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MessagesScreen({super.key, required this.onBack});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selectedCategory = 'all';
  final categories = ['all', 'announcement', 'devotional', 'prayer', 'newsletter'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Devotionals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ChoiceChip(
                    label: Text(category == 'all' ? 'All Messages' : category),
                    selected: isSelected,
                    selectedColor: Colors.purple,
                    backgroundColor: Colors.grey.shade300,
                    onSelected: (_) => setState(() => selectedCategory = category),
                  ),
                );
              }).toList(),
            ),
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs
                    .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((msg) => selectedCategory == 'all' || msg.category == selectedCategory)
                    .toList();

                if (messages.isEmpty) return const Center(child: Text('No messages found.'));

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Card(
                      color: msg.isRead ? Colors.white : Colors.blue[50],
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          msg.title,
                          style: TextStyle(fontWeight: msg.isRead ? null : FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${msg.author} • ${msg.timestamp.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: msg.isImportant ? const Icon(Icons.star, color: Colors.red) : null,
                        onTap: () async {
                          if (!msg.isRead) {
                            await FirebaseFirestore.instance
                                .collection('messages')
                                .doc(msg.id)
                                .update({'isRead': true});
                          }
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(msg.title),
                              content: SingleChildScrollView(child: Text(msg.content)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
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
