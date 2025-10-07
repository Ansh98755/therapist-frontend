// lib/services/reply_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:therapist_app/core/shared_pref.dart';

import '../models/add_reply_response.dart';
import '../models/reply_on_post_model.dart';

class ReplyService {
  static const String baseUrl = 'https://niti.nexuserp.co.in/api';

  /// Fetch replies for a given comment id.
  /// The API is POST to /post/getReply/{commentId} with Bearer token.
  static Future<List<ReplyModel>> fetchReplies(String commentId) async {
    final token = await SharedPrefService().getToken();

    final url = Uri.parse('$baseUrl/post/getReply/$commentId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body:
      jsonEncode({}), // API expects a POST with empty body as you mentioned
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Expect body['data'] to be an array of reply objects
      final List<dynamic> data = body['data'] ?? [];
      return data.map((e) => ReplyModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load replies: ${response.statusCode}');
    }
  }

  static Future<AddReplyResponse> addReply({
    required String commentId,
    required String commentUserId,
    required String replyText,
  }) async {
    final token = await SharedPrefService().getToken();
    final uName = await SharedPrefService().getFullName();
    final url = Uri.parse('$baseUrl/v1/post/addReply/$commentId/$commentUserId');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'posted_by': commentId,
        'comment': replyText,
        'user_name': uName,
      }),
    );

    print('Add Reply Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return AddReplyResponse.fromJson(body);
    } else {
      throw Exception('Failed to add reply: ${response.statusCode}');
    }
  }
}