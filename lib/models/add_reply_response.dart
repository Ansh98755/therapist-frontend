// lib/models/add_reply_response.dart
import 'package:therapist_app/models/reply_on_post_model.dart';

class AddReplyResponse {
  final String message;
  final ReplyModel reply;

  AddReplyResponse({
    required this.message,
    required this.reply,
  });

  factory AddReplyResponse.fromJson(Map<String, dynamic> json) {
    final message = (json['message'] ?? json['msg'] ?? '').toString();

    // 'reply' might be nested under 'reply' or returned as the whole object
    Map<String, dynamic> replyJson = {};
    if (json['reply'] is Map<String, dynamic>) {
      replyJson = Map<String, dynamic>.from(json['reply']);
    } else if (json['data'] is Map<String, dynamic>) {
      replyJson = Map<String, dynamic>.from(json['data']);
    } else if (json['reply'] is String) {
      // can't parse a string to object; keep it empty
      replyJson = {};
    }

    final reply = ReplyModel.fromJson(replyJson);

    return AddReplyResponse(message: message, reply: reply);
  }
}