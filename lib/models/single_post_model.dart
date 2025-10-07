class FetchPostResponse {
  final bool apiSuccess;
  final bool resSuccess;
  final PostData data;
  final String message;

  FetchPostResponse({
    required this.apiSuccess,
    required this.resSuccess,
    required this.data,
    required this.message,
  });

  factory FetchPostResponse.fromJson(Map<String, dynamic> json) {
    return FetchPostResponse(
      apiSuccess: json['apiSuccess'] == 1,
      resSuccess: json['resSuccess'] == 1,
      data: PostData.fromJson(json['data']),
      message: json['message'] ?? '',
    );
  }
}

class PostData {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  PostData({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
