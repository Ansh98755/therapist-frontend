import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post_model.dart';
import '../models/single_post_model.dart';
class CommunityApiService {
  static const String _baseUrl = 'https://niti.nexuserp.co.in/api';
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<PostModel>> fetchPosts({required int page}) async {
    print("PAGE VALUE: $page");
    final uri = Uri.parse("$_baseUrl/getAllPosts");

    // Add content-type header
    final headers = {
      'Content-Type': 'application/json',
      ...await _getAuthHeaders(),
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'page': page}),
    );
    print('Fetch posts Status Code: ${response.statusCode}');
    print("Fetch posts Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['posts'] as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } else {
      print("Response body (for debugging): ${response.body}");   // <-- add this temporarily
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  static Future<PostData> fetchPostById(String postId) async {
    final uri = Uri.parse("$_baseUrl/getPostById/$postId");
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final postResponse = FetchPostResponse.fromJson(body);
      return postResponse.data; // Only returning the post data
    } else {
      throw Exception('Failed to fetch post by ID: ${response.statusCode}');
    }
  }
}
