import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/post_model.dart';

class CommunityPostDbHelper {
  static Database? _db;
  static const String _table = 'community_posts';
  static Future<void> saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('community_last_page', page);
  }

  static Future<int> getLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('community_last_page') ?? 1;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'community_posts.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
  CREATE TABLE community_posts (
    id TEXT PRIMARY KEY,
    title TEXT,
    body TEXT,
    commentsEnabled INTEGER,
    postedById TEXT,
    postedByName TEXT,
    anonymous INTEGER,
    commentCount INTEGER,
    createdAt TEXT,
    postedByType TEXT
  )
''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE community_posts ADD COLUMN postedByType TEXT");
        }
      },
    );
  }

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<void> insertPosts(List<PostModel> posts) async {
    final db = await database;
    for (final post in posts) {
      await db.insert(
        _table,
        post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<PostModel>> getPosts() async {
    final db = await database;
    final res = await db.query(_table);
    return res.map((e) => PostModel.fromMap(e)).toList();
  }

  static Future<void> deleteAllPosts() async {
    final db = await database;
    await db.delete(_table);
  }
}