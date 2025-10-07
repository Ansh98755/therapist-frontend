class CreatedBy {
  final String id;
  final String fullName;
  final String pictureUrl;

  CreatedBy(
      {required this.id, required this.fullName, required this.pictureUrl});

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? json['fullname'] ?? '',
      pictureUrl: json['pictureUrl'] ?? json['pictureurl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'pictureUrl': pictureUrl,
    };
  }

  // ---- For sqflite ----
  factory CreatedBy.fromMap(Map<String, dynamic> map) {
    return CreatedBy(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      pictureUrl: map['pictureUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'pictureUrl': pictureUrl,
  };
}

class PostModel {
  final String id;
  final String title;
  final String body;
  final String postedByType;
  final bool commentsEnabled;
  final CreatedBy? postedBy; // updated field name
  final bool anonymous;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.postedByType,
    required this.body,
    required this.commentsEnabled,
    required this.postedBy,
    required this.anonymous,
    required this.commentCount,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      commentsEnabled: json['commentsEnabled'] ?? false,

      // postedBy: json['postedBy'] != null
      //     ? CreatedBy.fromJson(json['postedBy'])
      //     : null,

      postedBy:
      (json['postedBy'] != null && json['postedBy'] is Map<String, dynamic>)
          ? CreatedBy.fromJson(json['postedBy'])
          : null,
      postedByType: json['postedByType'] ?? '',
      anonymous: json['anonymous'] ?? false,
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'body': body,
      'commentsEnabled': commentsEnabled,
      'postedBy': postedBy?.toJson(),
      'anonymous': anonymous,
      'commentCount': commentCount,
      'postedByType': postedByType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ---- For sqflite ----
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      commentsEnabled: (map['commentsEnabled'] ?? 0) == 1,
      postedBy: map['postedById'] != null
          ? CreatedBy(
        id: map['postedById'],
        fullName: map['postedByName'] ?? '',
        pictureUrl: map['postedByPictureUrl'] ?? '',
      )
          : null,
      postedByType: map['postedByType'] ?? '',
      anonymous: (map['anonymous'] ?? 0) == 1,
      commentCount: map['commentCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'commentsEnabled': commentsEnabled ? 1 : 0,
      'postedById': postedBy?.id,
      'postedByName': postedBy?.fullName,
      'anonymous': anonymous ? 1 : 0,
      'commentCount': commentCount,
      'postedByType': postedByType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}