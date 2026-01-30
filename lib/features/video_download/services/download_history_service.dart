import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/downloaded_video_model.dart';

/// 视频下载历史服务
/// 从实际下载目录读取文件，而不是单独维护记录
class DownloadHistoryService {
  DownloadHistoryService._();

  static final DownloadHistoryService _instance = DownloadHistoryService._();

  factory DownloadHistoryService() => _instance;

  static const String _metadataKey = 'video_metadata';
  final List<DownloadedVideoModel> _videos = [];
  Directory? _downloadDirectory;

  /// 获取所有已下载视频
  List<DownloadedVideoModel> get videos => List.unmodifiable(_videos);

  /// 是否为空
  bool get isEmpty => _videos.isEmpty;

  /// 视频数量
  int get length => _videos.length;

  /// 初始化服务
  Future<void> init() async {
    await _getDownloadDirectory();
    await _scanDownloadDirectory();
  }

  /// 获取下载目录
  Future<void> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        _downloadDirectory = Directory('${directory.path}/Movies');
      }
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      _downloadDirectory = Directory('${directory.path}/Videos');
    }

    // 确保目录存在
    if (_downloadDirectory != null && !await _downloadDirectory!.exists()) {
      await _downloadDirectory!.create(recursive: true);
    }

    print('下载目录: ${_downloadDirectory?.path}');
  }

  /// 扫描下载目录中的视频文件
  Future<void> _scanDownloadDirectory() async {
    if (_downloadDirectory == null) {
      print('下载目录未初始化');
      return;
    }

    _videos.clear();

    try {
      final files = await _downloadDirectory!.list().toList();
      final metadataMap = await _loadMetadata();

      for (var file in files) {
        if (file is File && _isVideoFile(file)) {
          try {
            final stat = await file.stat();
            final fileName = file.path.split('/').last;

            // 从元数据中获取额外信息
            final metadata = metadataMap[fileName];
            final video = DownloadedVideoModel(
              id: fileName,
              title: metadata?['title'] ?? _extractTitleFromFileName(fileName),
              author: metadata?['author'] ?? '未知',
              platform: metadata?['platform'] ?? _guessPlatform(fileName),
              description: metadata?['description'] ?? '',
              coverUrl: metadata?['coverUrl'] ?? '',
              videoUrl: file.path,
              localPath: file.path,
              fileSize: stat.size,
              downloadedAt: stat.modified,
              duration: metadata?['duration'],
            );

            _videos.add(video);
          } catch (e) {
            print('处理文件失败: ${file.path}, 错误: $e');
          }
        }
      }

      // 按修改时间排序（最新的在前）
      _videos.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

      print('扫描完成，找到 ${_videos.length} 个视频文件');
    } catch (e) {
      print('扫描下载目录失败: $e');
    }
  }

  /// 判断是否为视频文件
  bool _isVideoFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.flv') ||
        path.endsWith('.wmv');
  }

  /// 从文件名提取标题
  String _extractTitleFromFileName(String fileName) {
    // 移除扩展名
    String title = fileName.replaceAll(RegExp(r'\.(mp4|mov|avi|mkv|flv|wmv)$'), '');
    // 移除时间戳
    title = title.replaceAll(RegExp(r'_\d+$'), '');
    // 替换下划线为空格
    title = title.replaceAll('_', ' ');
    return title.isEmpty ? '未命名视频' : title;
  }

  /// 从文件名猜测平台
  String _guessPlatform(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('douyin') || lower.contains('抖音')) {
      return 'douyin';
    } else if (lower.contains('tiktok')) {
      return 'tiktok';
    } else if (lower.contains('youtube')) {
      return 'youtube';
    } else if (lower.contains('bilibili') || lower.contains('bilibili')) {
      return 'bilibili';
    }
    return 'unknown';
  }

  /// 刷新视频列表
  Future<void> refresh() async {
    await _scanDownloadDirectory();
  }

  /// 保存视频元数据（标题、作者等额外信息）
  Future<void> _saveMetadata(DownloadedVideoModel video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataMap = await _loadMetadata();

      final fileName = video.localPath.split('/').last;
      metadataMap[fileName] = {
        'title': video.title,
        'author': video.author,
        'platform': video.platform,
        'description': video.description,
        'coverUrl': video.coverUrl,
        'duration': video.duration,
      };

      final json = jsonEncode(metadataMap);
      await prefs.setString(_metadataKey, json);
      print('已保存元数据: $fileName');
    } catch (e) {
      print('保存元数据失败: $e');
    }
  }

  /// 加载所有元数据
  Future<Map<String, dynamic>> _loadMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_metadataKey);
      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        return data.cast<String, dynamic>();
      }
    } catch (e) {
      print('加载元数据失败: $e');
    }
    return {};
  }

  /// 添加视频元数据（下载成功后调用）
  Future<void> addVideo(DownloadedVideoModel video) async {
    // 只保存元数据，不维护单独的列表
    await _saveMetadata(video);
    // 重新扫描目录
    await _scanDownloadDirectory();
  }

  /// 删除视频（实际删除文件）
  Future<void> deleteVideo(String id) async {
    try {
      final video = _videos.firstWhere((v) => v.id == id);
      final file = File(video.localPath);

      if (await file.exists()) {
        await file.delete();
        print('已删除文件: ${video.localPath}');
      }

      // 重新扫描目录
      await _scanDownloadDirectory();
    } catch (e) {
      print('删除视频失败: $e');
      rethrow;
    }
  }

  /// 清空所有记录（删除所有文件）
  Future<void> clearAll() async {
    try {
      if (_downloadDirectory == null) return;

      final files = await _downloadDirectory!.list().toList();
      for (var file in files) {
        if (file is File && _isVideoFile(file)) {
          await file.delete();
        }
      }

      await _scanDownloadDirectory();
      print('已清空所有下载文件');
    } catch (e) {
      print('清空失败: $e');
      rethrow;
    }
  }

  /// 根据ID查找视频
  DownloadedVideoModel? findVideo(String id) {
    try {
      return _videos.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取总文件大小
  int getTotalSize() {
    return _videos.fold(0, (sum, video) => sum + video.fileSize);
  }

  /// 格式化的总大小
  String getTotalSizeFormatted() {
    final totalSize = getTotalSize();
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 按平台分组
  Map<String, List<DownloadedVideoModel>> getVideosByPlatform() {
    final Map<String, List<DownloadedVideoModel>> grouped = {};
    for (var video in _videos) {
      if (!grouped.containsKey(video.platform)) {
        grouped[video.platform] = [];
      }
      grouped[video.platform]!.add(video);
    }
    return grouped;
  }

  /// 搜索视频
  List<DownloadedVideoModel> searchVideos(String keyword) {
    if (keyword.isEmpty) return List.from(_videos);

    final lowerKeyword = keyword.toLowerCase();
    return _videos.where((video) {
      return video.title.toLowerCase().contains(lowerKeyword) ||
          video.author.toLowerCase().contains(lowerKeyword) ||
          video.description.toLowerCase().contains(lowerKeyword);
    }).toList();
  }

  /// 获取最近下载的视频
  List<DownloadedVideoModel> getRecentVideos({int limit = 10}) {
    return _videos.take(limit).toList();
  }

  /// 获取下载目录路径
  String? getDownloadDirectoryPath() {
    return _downloadDirectory?.path;
  }

  /// 检查文件是否存在
  Future<bool> checkFileExists(String localPath) async {
    try {
      final file = File(localPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
