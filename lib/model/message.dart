import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String title;
  final String content;
  final String author;
  final String category;
  final DateTime timestamp;
  final bool isRead;
  final bool isImportant;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.category,
    required this.timestamp,
    required this.isRead,
    required this.isImportant,
  });

  /// Save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp), //  fixed
      'isRead': isRead,
      'isImportant': isImportant,
    };
  }

  /// Read from Firestore
  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? 'announcement',
      timestamp: (map['timestamp'] as Timestamp).toDate(), //  safe conversion
      isRead: map['isRead'] ?? false,
      isImportant: map['isImportant'] ?? false,
    );
  }
}
