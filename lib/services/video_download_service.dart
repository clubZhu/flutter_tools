import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:calculator_app/models/video_info.dart';
import 'package:calculator_app/network/api_client.dart';
import 'package:calculator_app/services/video_parser_service.dart';
import 'package:calculator_app/services/tiktok_parser_service.dart';

/// 视频下载服务
class VideoDownloadService {
  VideoDownloadService._();

  static final VideoDownloadService _instance = VideoDownloadService._();

  factory VideoDownloadService() => _instance;

  final Dio _dio = Dio();

  /// 识别分享链接的平台
  String? identifyPlatform(String url) {
    if (url.isEmpty) return null;

    if (url.contains('douyin.com') || url.contains('iesdouyin.com')) {
      return 'douyin';
    } else if (url.contains('tiktok.com')) {
      return 'tiktok';
    } else if (url.contains('bilibili.com') || url.contains('b23.tv')) {
      return 'bilibili';
    } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'youtube';
    } else if (url.contains('weibo.com')) {
      return 'weibo';
    } else if (url.contains('kuaishou.com') || url.contains('chenzhongtech.com')) {
      return 'kuaishou';
    }

    return 'unknown';
  }

  /// 解析视频分享链接
  /// 支持YouTube、TikTok、抖音等平台
  Future<VideoInfo?> parseVideoUrl(String shareUrl) async {
    try {
      final platform = identifyPlatform(shareUrl);

      // YouTube使用真实解析
      if (platform == 'youtube') {
        return await YouTubeParserService().parseYouTubeVideo(shareUrl);
      }

      // TikTok和抖音使用真实API解析
      if (platform == 'douyin' || platform == 'tiktok') {
        final videoInfo = await TikTokParserService().parseVideo(shareUrl);
        if (videoInfo != null) {
          return videoInfo;
        }

        // API失败时返回提示
        return VideoInfo(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          title: '解析失败',
          description: '无法解析${platform == 'douyin' ? '抖音' : 'TikTok'}视频。\n\n可能原因：\n1. 链接无效或已删除\n2. API服务暂时不可用\n3. 网络连接问题\n\n请检查链接后重试，或尝试其他视频。',
          coverUrl: 'https://via.placeholder.com/400x600?text=Parse+Error',
          videoUrl: '',
          author: '未知',
          platform: platform,
          duration: null,
        );
      }

      // 其他平台使用模拟数据
      await Future.delayed(const Duration(seconds: 1));
      return VideoInfo(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        title: '视频标题 ($platform)',
        description: '视频描述\n\n提示：$platform 平台的视频解析需要对接相应的API服务。',
        coverUrl: 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}',
        videoUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
        author: '作者',
        platform: platform,
        duration: 30000,
      );
    } catch (e) {
      print('解析视频链接失败: $e');
      return null;
    }
  }

  /// 使用真实API解析（示例方法，需要根据实际API调整）
  Future<VideoInfo?> parseWithRealAPI(String shareUrl) async {
    try {
      final response = await ApiClient().post<Map<String, dynamic>>(
        '/video/parse',
        data: {'url': shareUrl},
      );

      if (response.isSuccess && response.data != null) {
        return VideoInfo.fromJson(response.data!);
      }

      return null;
    } catch (e) {
      print('API解析失败: $e');
      return null;
    }
  }

  /// 请求存储权限
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) 需要照片/视频权限
      if (Platform.version.contains('33') || Platform.version.contains('34')) {
        final status = await Permission.photos.request();
        if (status.isGranted) {
          return true;
        }
        // 如果被拒绝，显示权限设置说明
        if (status.isPermanentlyDenied) {
          return false;
        }
      }

      // Android 12 及以下
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // 如果被永久拒绝，打开设置
      if (status.isPermanentlyDenied) {
        return false;
      }

      return false;
    } else if (Platform.isIOS) {
      // iOS 使用照片库权限
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true;
  }

  /// 下载视频
  Future<File?> downloadVideo(
    String videoUrl,
    String fileName, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // 检查URL
      if (videoUrl.isEmpty) {
        throw Exception('视频URL为空');
      }

      // 请求权限
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('没有存储权限，请在设置中允许访问存储');
      }

      // 获取保存目录
      final directory = await _getSaveDirectory();
      if (directory == null) {
        throw Exception('无法获取保存目录');
      }

      // 确保目录存在
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final savePath = '${directory.path}/$fileName';

      print('开始下载: $videoUrl');
      print('保存到: $savePath');

      // 下载文件
      await _dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      // 验证文件是否下载成功
      final file = File(savePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('下载完成，文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        return file;
      } else {
        throw Exception('文件下载失败，未找到保存的文件');
      }
    } catch (e) {
      print('下载视频失败: $e');
      return null;
    }
  }

  /// 获取保存目录
  Future<Directory?> _getSaveDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Android 10+ 使用应用专用目录
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Movies');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      } else if (Platform.isIOS) {
        // iOS 使用应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${directory.path}/Videos');
        if (!await videoDir.exists()) {
          await videoDir.create(recursive: true);
        }
        return videoDir;
      }

      // 降级方案：使用临时目录
      final tempDir = await getTemporaryDirectory();
      final videoDir = Directory('${tempDir.path}/Videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      return videoDir;
    } catch (e) {
      print('获取保存目录失败: $e');
      return null;
    }
  }

  /// 生成安全的文件名
  String generateSafeFileName(String title) {
    // 移除非法字符
    String safeName = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');

    // 限制长度
    if (safeName.length > 50) {
      safeName = safeName.substring(0, 50);
    }

    // 去除首尾空格
    safeName = safeName.trim();

    // 如果为空，使用默认名称
    if (safeName.isEmpty) {
      safeName = 'video';
    }

    // 添加时间戳和扩展名
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeName}_$timestamp.mp4';
  }

  /// 获取下载文件的完整路径
  Future<String> getDownloadFilePath(String fileName) async {
    final directory = await _getSaveDirectory();
    if (directory != null) {
      return '${directory.path}/$fileName';
    }
    return fileName;
  }

  /// 取消下载
  void cancelDownload(CancelToken cancelToken) {
    cancelToken.cancel('用户取消下载');
  }
}
