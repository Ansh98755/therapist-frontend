// lib/providers/replies_provider.dart
import 'package:flutter/material.dart';

import '../api_services/reply_service.dart';
import '../models/add_reply_response.dart';
import '../models/reply_on_post_model.dart';
class RepliesProvider extends ChangeNotifier {
  // cache replies per comment id
  final Map<String, List<ReplyModel>> _repliesMap = {};

  // loading states per comment id
  final Set<String> _loadingIds = {};

  final Set<String> _postingIds = {};

  List<ReplyModel> getRepliesFor(String commentId) =>
      _repliesMap[commentId] ?? [];

  bool isLoading(String commentId) => _loadingIds.contains(commentId);
  bool isPosting(String commentId) => _postingIds.contains(commentId);

  /// fetch replies from API (will overwrite cache)
  Future<void> fetchReplies(String commentId) async {
    // prevent duplicate concurrent calls
    if (_loadingIds.contains(commentId)) return;

    _loadingIds.add(commentId);
    notifyListeners();

    try {
      final replies = await ReplyService.fetchReplies(commentId);
      _repliesMap[commentId] = replies;
    } catch (e) {
      // keep previous cached replies if any; you could set empty if you prefer
      _repliesMap[commentId] = _repliesMap[commentId] ?? [];
      debugPrint('[RepliesProvider] error fetching replies for $commentId: $e');
    } finally {
      _loadingIds.remove(commentId);
      notifyListeners();
    }
  }

  Future<bool> postReply({
    required String commentId,
    required String commentUserId,
    required String replyText,
  }) async {
    // avoid double-post
    if (_postingIds.contains(commentId)) return false;

    _postingIds.add(commentId);
    notifyListeners();

    try {
      final AddReplyResponse res = await ReplyService.addReply(
        commentId: commentId,
        commentUserId: commentUserId,
        replyText: replyText,
      );

      // Optionally: immediately insert the returned reply into cache
      final returned = res.reply;
      final list = _repliesMap[commentId] ?? [];
      // insert at start (depending on desired order)
      list.insert(0, returned);
      _repliesMap[commentId] = list;

      // re-fetch from server to ensure consistency / get updated list
      await fetchReplies(commentId);

      return true;
    } catch (e) {
      debugPrint('[RepliesProvider] error posting reply for $commentId: $e');
      return false;
    } finally {
      _postingIds.remove(commentId);
      notifyListeners();
    }
  }

  /// Optionally add a reply locally (optimistic)
  void addReplyLocal(String commentId, ReplyModel reply) {
    final list = _repliesMap[commentId] ?? [];
    list.insert(0, reply);
    _repliesMap[commentId] = list;
    notifyListeners();
  }

  /// clear replies for a comment
  void clearReplies(String commentId) {
    _repliesMap.remove(commentId);
    notifyListeners();
  }
}