import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:therapist_app/core/shared_pref.dart';
import '../api_services/community_api_service.dart';
import '../local_db/community_post_db_helper.dart';
import '../models/post_model.dart';

class CommunityProvider extends ChangeNotifier {
  final List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  bool _isLoading = false;
  bool _isHomePageLoading = false;
  bool get isLoading => _isLoading;
  bool get isHomePageLoading => _isHomePageLoading;

  int _page = 1;
  bool _hasMore = true;
  bool get hasReachedEnd => !_hasMore;

  final Map<String, bool> _likedPosts = {};
  final Map<String, int> _likeCounts = {};
  final Set<String> _likingInProgress = {};

  bool isPostLiked(String postId) => _likedPosts[postId] ?? false;
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;
  bool isLiking(String postId) => _likingInProgress.contains(postId);

  Future<void> toggleLikePost(
      {required String postId,
      required String token,
      required String? postedBy}) async {
    if (_likingInProgress.contains(postId)) return;

    _likingInProgress.add(postId);
    notifyListeners();

    try {
      final bool isLikedNow = _likedPosts[postId] ?? false;
      final String? userName = await SharedPrefService().getFullName();
      final url = Uri.parse(
        isLikedNow
            ? 'https://niti.nexuserp.co.in/api/post/removeLike'
            : 'https://niti.nexuserp.co.in/api/v1/post/likes',
      );
      print('[DEBUG] Sending like request to: ${url.toString()}');
      print('[DEBUG] Post ID: $postId, Current like state: $isLikedNow');
      print('[DEBUG] Posted by: $postedBy');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {
              'post_id': postId,
              postedBy != null ? 'posted_by' : postedBy: '',
              'user_name': userName
            }),
      );

      print(
          '[DEBUG] Like toggle: $postId, isLikedNow: $isLikedNow, status: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      // Handle both 200 and 204 status codes as success
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Update local state immediately
        _likedPosts[postId] = !isLikedNow;
        _likeCounts[postId] =
            (_likeCounts[postId] ?? 0) + (isLikedNow ? -1 : 1);

        print(
            '[DEBUG] Successfully updated local state. New like state: ${_likedPosts[postId]}');
        print('[DEBUG] New like count: ${_likeCounts[postId]}');

        // Don't immediately refresh from backend to avoid race conditions
        // The state will be refreshed when posts are fetched again
      } else {
        print('Toggle like failed: ${response.statusCode} ${response.body}');
        // Don't revert state on failure - let user see the attempt
      }
    } catch (e) {
      print('Error in toggleLikePost: $e');
      // Don't revert state on error - let user see the attempt
    } finally {
      _likingInProgress.remove(postId);
      notifyListeners();
    }
  }

  Future<void> getLikesForPosts(List<String> postIds, String token,
      {bool forceUpdate = false}) async {
    try {
      final url = Uri.parse('https://niti.nexuserp.co.in/api/post/getLikes');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': postIds}),
      );

      print(
          '[DEBUG] getLikesForPosts response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> likes = data['likes'];

        for (final entry in likes.entries) {
          final postId = entry.key;
          final info = entry.value;
          final newCount = info['count'] ?? 0;
          final newLikedState = info['liked_by_user'] ?? false;

          print(
              '[DEBUG] Post $postId - Backend: count=$newCount, liked=$newLikedState, Local: count=${_likeCounts[postId]}, liked=${_likedPosts[postId]}');

          // Always update count from backend
          _likeCounts[postId] = newCount;

          // Only update liked status if:
          // 1. We don't have local state for this post, OR
          // 2. Force update is requested (for initial load)
          if (!_likedPosts.containsKey(postId) || forceUpdate) {
            _likedPosts[postId] = newLikedState;
            print(
                '[DEBUG] Updated like state for post $postId to $newLikedState');
          } else {
            print(
                '[DEBUG] Preserved local like state for post $postId: ${_likedPosts[postId]}');
          }
        }

        notifyListeners();
      } else {
        print('Get likes failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error in getLikesForPosts: $e');
    }
  }

  Future<void> fetchPosts({bool reset = false, String? token}) async {
    if (_isLoading || (!_hasMore && !reset)) {
      print(
          "⚠️ Skipping fetch: isLoading=$_isLoading, hasMore=$_hasMore, reset=$reset");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (reset) {
        print("🔄 Resetting posts and DB...");
        _posts.clear();
        _page = 1;
        _hasMore = true;
        await CommunityPostDbHelper.deleteAllPosts();
      }

      // ✅ Load from DB first if opening fresh
      if (_page == 1 && _posts.isEmpty) {
        final cached = await CommunityPostDbHelper.getPosts();
        if (cached.isNotEmpty) {
          _posts.addAll(cached);
          _page = (await CommunityPostDbHelper.getLastPage()) + 1;
          print(
              "📦 Loaded ${cached.length} posts from DB (page restored: $_page)");
          notifyListeners();
        } else {
          print("📭 No posts found in DB, will fetch from API...");
        }
      }

      // 🔥 Fetch from API
      final fetchedPosts = await CommunityApiService.fetchPosts(page: _page);

      if (fetchedPosts.isEmpty) {
        _hasMore = false;
        print("🚫 No more posts from API (page $_page).");
      } else {
        print(
            "🌐 Fetched ${fetchedPosts.length} posts from API (page $_page).");
        _posts.addAll(fetchedPosts);

        // ✅ Save to DB
        if (_page == 1) {
          print("🗑️ Clearing DB before inserting first page...");
          await CommunityPostDbHelper.deleteAllPosts();
        }
        await CommunityPostDbHelper.insertPosts(fetchedPosts);
        await CommunityPostDbHelper.saveLastPage(_page);
        print("💾 Saved ${fetchedPosts.length} posts to DB (page $_page).");

        _page++; // next page
      }

      // update likes
      if (token != null && fetchedPosts.isNotEmpty) {
        final ids = fetchedPosts.map((e) => e.id).whereType<String>().toList();
        if (ids.isNotEmpty) {
          print("❤️ Fetching likes for ${ids.length} posts...");
          await getLikesForPosts(ids, token, forceUpdate: reset);
        }
      }
    } catch (e) {
      print('❌ Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchHomePosts({String? token}) async {
  //   if (_isLoading || (!_hasMore)) return;

  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     // if (reset) {
  //     //   _posts.clear();
  //     //   _page = 0;
  //     //   _hasMore = true;
  //     //   // Clear like states when resetting to ensure fresh data
  //     //   // _likedPosts.clear();
  //     //   // _likeCounts.clear();
  //     // }

  //     final fetchedPosts = await CommunityApiService.getHomePagePosts();
  //     if (fetchedPosts.isNotEmpty) {
  //       _homePagePosts.addAll(fetchedPosts);
  //     }

  //     // if (fetchedPosts.isEmpty) {
  //     //   _hasMore = false;
  //     // } else {
  //     //   _posts.addAll(fetchedPosts);
  //     //   _page++;

  //     //   // if (token != null) {
  //     //   //   final ids =
  //     //   //       fetchedPosts.map((e) => e.id).whereType<String>().toList();
  //     //   //   if (ids.isNotEmpty) {
  //     //   //     await getLikesForPosts(ids, token, forceUpdate: reset);
  //     //   //   }
  //     //   // }
  //     // }
  //   } catch (e) {
  //     print("Error fetching posts: $e");
  //   } finally {
  //     _isLoading = false;
  //     _isHomePageLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Method to refresh likes for all current posts
  Future<void> refreshLikes(String token) async {
    if (_posts.isEmpty) return;

    final ids = _posts.map((e) => e.id).whereType<String>().toList();
    if (ids.isNotEmpty) {
      await getLikesForPosts(ids, token, forceUpdate: true);
    }
  }

  // Method to handle app lifecycle changes
  Future<void> onAppResumed(String token) async {
    // Refresh likes when app comes back to foreground
    await refreshLikes(token);
  }

  // Method to clear all data (useful for logout)
  void clearData() {
    _posts.clear();
    _likedPosts.clear();
    _likeCounts.clear();
    _likingInProgress.clear();
    _page = 0;
    _hasMore = true;
    _isLoading = false;
    notifyListeners();
  }
}
