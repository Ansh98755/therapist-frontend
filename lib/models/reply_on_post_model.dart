// lib/models/reply_model.dart
import 'package:intl/intl.dart';

class ReplyModel {
  final String id;
  final String? userId;
  final String replyText;
  final int? priority;
  final DateTime createdAt;

  ReplyModel({
    required this.id,
    this.userId,
    required this.replyText,
    this.priority,
    required this.createdAt,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    // id
    final id = (json['_id'] ?? json['id'] ?? '').toString();

    // userId: backend may return either a string or a nested object { _id: '...' }
    String? userId;
    final rawUser = json['user_id'] ?? json['userId'] ?? json['posted_by'];
    if (rawUser != null) {
      if (rawUser is String) {
        userId = rawUser;
      } else if (rawUser is Map && rawUser.containsKey('_id')) {
        userId = rawUser['_id']?.toString();
      } else {
        // try toString fallback
        userId = rawUser.toString();
      }
    }

    // reply text: server may use 'reply_text' or 'comment'
    String replyText = '';
    if (json.containsKey('reply_text') && json['reply_text'] != null) {
      replyText = json['reply_text'].toString();
    } else if (json.containsKey('comment') && json['comment'] != null) {
      replyText = json['comment'].toString();
    } else if (json.containsKey('reply') && json['reply'] is String) {
      replyText = json['reply'];
    } else {
      // fallback to any plausible field
      replyText = (json['text'] ?? json['message'] ?? '').toString();
    }

    // Priority: may be int or string
    int? priority;
    final rawPriority = json['Priority'] ?? json['priority'];
    if (rawPriority != null) {
      if (rawPriority is int) {
        priority = rawPriority;
      } else {
        priority = int.tryParse(rawPriority.toString());
      }
    }

    // created_at: parse safely
    DateTime createdAt;
    final rawCreated =
        json['created_at'] ?? json['createdAt'] ?? json['created'];
    if (rawCreated == null) {
      createdAt = DateTime.now();
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else {
      createdAt = DateTime.tryParse(rawCreated.toString()) ?? DateTime.now();
    }

    return ReplyModel(
      id: id,
      userId: userId,
      replyText: replyText,
      priority: priority,
      createdAt: createdAt,
    );
  }

  String formattedDate() {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());
  }
}