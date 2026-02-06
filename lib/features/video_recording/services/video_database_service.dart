import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/video_recording_model.dart';

/// 视频录制数据库服务
class VideoDatabaseService {
  static final VideoDatabaseService _instance = VideoDatabaseService._internal();
  factory VideoDatabaseService() => _instance;
  VideoDatabaseService._internal();

  static Database? _database;

  // 数据库名称和版本
  static const String _databaseName = 'video_recordings.db';
  static const int _databaseVersion = 1;

  // 表名
  static const String _tableName = 'video_recordings';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        filePath TEXT NOT NULL,
        thumbnailPath TEXT NOT NULL,
        name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        fileSize INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        modifiedAt TEXT
      )
    ''');
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时使用
  }

  /// 插入视频记录
  Future<int> insertVideo(VideoRecordingModel video) async {
    final db = await database;
    return await db.insert(
      _tableName,
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有视频记录
  Future<List<VideoRecordingModel>> getAllVideos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      return VideoRecordingModel.fromMap(maps[i]);
    });
  }

  /// 根据ID获取视频记录
  Future<VideoRecordingModel?> getVideoById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return VideoRecordingModel.fromMap(maps.first);
  }

  /// 更新视频记录
  Future<int> updateVideo(VideoRecordingModel video) async {
    final db = await database;
    return await db.update(
      _tableName,
      video.toMap(),
      where: 'id = ?',
      whereArgs: [video.id],
    );
  }

  /// 删除视频记录
  Future<int> deleteVideo(String id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除所有视频记录
  Future<int> deleteAllVideos() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  /// 获取视频记录总数
  Future<int> getVideosCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 搜索视频记录
  Future<List<VideoRecordingModel>> searchVideos(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      return VideoRecordingModel.fromMap(maps[i]);
    });
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
