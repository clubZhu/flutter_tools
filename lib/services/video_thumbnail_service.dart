import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:dio/dio.dart';

/// 视频缩略图生成服务
/// 为下载的视频生成本地缩略图或缓存封面图
class VideoThumbnailService {
  VideoThumbnailService._();
  static final VideoThumbnailService _instance = VideoThumbnailService._();
  factory VideoThumbnailService() => _instance;

  final Dio _dio = Dio();

  /// 生成视频缩略图
  ///
  /// [videoPath] 视频文件的本地路径
  /// [videoId] 视频ID，用于生成唯一的缩略图文件名
  ///
  /// 返回缩略图的本地路径，如果生成失败则返回空字符串
  Future<String> generateThumbnail(String videoPath, String videoId) async {
    try {
      // 检查视频文件是否存在
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        print('视频文件不存在: $videoPath');
        return '';
      }

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory('${appDir.path}/download_thumbnails');

      // 创建缩略图目录
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // 生成缩略图文件名（使用视频ID确保唯一性）
      final thumbnailPath = '${thumbnailDir.path}/$videoId.jpg';

      // 检查缩略图是否已存在
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        print('缩略图已存在: $thumbnailPath');
        return thumbnailPath;
      }

      // 生成缩略图
      print('开始生成缩略图: $videoPath -> $thumbnailPath');
      final uint8list = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 1080, // 提高分辨率
        maxHeight: (1080 * 16 / 9).toInt(), // 16:9 比例
        quality: 90, // 提高质量
        timeMs: 1000, // 从第1秒开始截取
      );

      // 检查是否成功生成
      if (uint8list == null || uint8list.isEmpty) {
        print('缩略图生成失败: 返回数据为空');
        return '';
      }

      // 保存缩略图
      await thumbnailFile.writeAsBytes(uint8list);
      print('缩略图生成成功: $thumbnailPath');

      return thumbnailPath;
    } catch (e) {
      print('生成缩略图失败: $e');
      return ''; // 失败时返回空字符串
    }
  }

  /// 批量生成缩略图
  ///
  /// [videos] 视频列表，每个视频包含 localPath 和 id
  /// 返回生成的缩略图路径映射 {videoId: thumbnailPath}
  Future<Map<String, String>> generateBatchThumbnails(
    List<Map<String, String>> videos,
  ) async {
    final Map<String, String> thumbnailPaths = {};

    for (var video in videos) {
      final videoPath = video['localPath'] ?? '';
      final videoId = video['id'] ?? '';

      if (videoPath.isEmpty || videoId.isEmpty) continue;

      final thumbnailPath = await generateThumbnail(videoPath, videoId);
      if (thumbnailPath.isNotEmpty) {
        thumbnailPaths[videoId] = thumbnailPath;
      }
    }

    return thumbnailPaths;
  }

  /// 下载并缓存封面图
  ///
  /// [coverUrl] 封面图的URL地址
  /// [videoId] 视频ID，用于生成唯一的文件名
  ///
  /// 返回保存的封面图本地路径，如果下载失败则返回空字符串
  Future<String> downloadAndCacheCover(String coverUrl, String videoId) async {
    try {
      // 检查URL是否有效
      if (coverUrl.isEmpty || !coverUrl.startsWith('http')) {
        print('封面URL无效: $coverUrl');
        return '';
      }

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${appDir.path}/video_covers');

      // 创建封面目录
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      // 生成封面文件名
      final fileExtension = _getFileExtension(coverUrl);
      final coverPath = '${coverDir.path}/$videoId.$fileExtension';

      // 检查封面是否已存在
      final coverFile = File(coverPath);
      if (await coverFile.exists()) {
        print('封面已缓存: $coverPath');
        return coverPath;
      }

      // 下载封面
      print('开始下载封面: $coverUrl -> $coverPath');
      final response = await _dio.get(
        coverUrl,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // 保存封面
        await coverFile.writeAsBytes(response.data);
        print('封面下载成功: $coverPath');
        return coverPath;
      } else {
        print('封面下载失败: HTTP ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('下载封面失败: $e');
      return '';
    }
  }

  /// 从URL获取文件扩展名
  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final extension = path.split('.').last.toLowerCase();

      // 支持的图片格式
      const supportedFormats = ['jpg', 'jpeg', 'png', 'webp'];
      if (supportedFormats.contains(extension)) {
        return extension;
      }

      // 默认使用jpg
      return 'jpg';
    } catch (e) {
      return 'jpg';
    }
  }

  /// 删除指定视频的缩略图
  Future<bool> deleteThumbnail(String videoId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailPath = '${appDir.path}/download_thumbnails/$videoId.jpg';
      final thumbnailFile = File(thumbnailPath);

      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
        print('缩略图已删除: $thumbnailPath');
        return true;
      }

      return false;
    } catch (e) {
      print('删除缩略图失败: $e');
      return false;
    }
  }

  /// 清理所有缩略图
  Future<int> clearAllThumbnails() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory('${appDir.path}/download_thumbnails');

      if (!await thumbnailDir.exists()) {
        return 0;
      }

      int count = 0;
      await for (final entity in thumbnailDir.list()) {
        if (entity is File) {
          await entity.delete();
          count++;
        }
      }

      print('已清理 $count 个缩略图');
      return count;
    } catch (e) {
      print('清理缩略图失败: $e');
      return 0;
    }
  }

  /// 获取缩略图路径
  Future<String?> getThumbnailPath(String videoId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailPath = '${appDir.path}/download_thumbnails/$videoId.jpg';
      final thumbnailFile = File(thumbnailPath);

      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }

      return null;
    } catch (e) {
      print('获取缩略图路径失败: $e');
      return null;
    }
  }
}
