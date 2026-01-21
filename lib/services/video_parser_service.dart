import 'package:calculator_app/services/tiktok_parser_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:calculator_app/models/video_info.dart';

/// YouTube视频解析服务
class YouTubeParserService {
  YouTubeParserService._();

  static final YouTubeParserService _instance = YouTubeParserService._();

  factory YouTubeParserService() => _instance;

  final YoutubeExplode _yt = YoutubeExplode();

  /// 解析YouTube视频
  Future<VideoInfo?> parseYouTubeVideo(String url) async {
    try {
      // 从URL获取视频ID
      final videoId = VideoId(url);

      // 获取视频元数据
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();

      return VideoInfo(
        id: video.id.value,
        title: video.title,
        description: video.description,
        coverUrl: video.thumbnails.highResUrl,
        videoUrl: streamInfo.url.toString(),
        author: video.author,
        platform: 'youtube',
        duration: video.duration?.inMilliseconds,
      );
    } catch (e) {
      print('解析YouTube视频失败: $e');
      return null;
    }
  }

  /// 获取所有可用的视频流
  Future<Map<String, String>> getVideoStreams(String url) async {
    try {
      final videoId = VideoId(url);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      final streams = <String, String>{};

      // 获取 muxed streams (音视频合并)
      for (final stream in manifest.muxed) {
        final quality = '${stream.videoQuality} - ${stream.size.totalMegaBytes.toStringAsFixed(2)}MB';
        streams[quality] = stream.url.toString();
      }

      return streams;
    } catch (e) {
      print('获取视频流失败: $e');
      return {};
    }
  }

  /// 搜索YouTube视频
  Future<List<VideoInfo>> searchVideos(String query, {int count = 10}) async {
    try {
      final searchResults = await _yt.search.search(query);
      final results = <VideoInfo>[];

      for (final video in searchResults) {
        if (results.length >= count) break;

        if (video is Video) {
          try {
            final manifest = await _yt.videos.streamsClient.getManifest(video.id);
            final streamInfo = manifest.muxed.withHighestBitrate();

            results.add(VideoInfo(
              id: video.id.value,
              title: video.title,
              description: video.description,
              coverUrl: video.thumbnails.highResUrl,
              videoUrl: streamInfo.url.toString(),
              author: video.author,
              platform: 'youtube',
              duration: video.duration?.inMilliseconds,
            ));
          } catch (e) {
            print('解析搜索结果失败: $e');
          }
        }
      }

      return results;
    } catch (e) {
      print('搜索失败: $e');
      return [];
    }
  }

  /// 释放资源
  void dispose() {
    _yt.close();
  }
}

/// B站解析服务说明
///
/// B站的视频解析比较复杂，需要：
/// 1. 获取视频信息API
/// 2. 解析视频流URL（需要处理签名）
///
/// 推荐使用第三方库或API：
/// - bilibili-api (Python)
/// - 或者使用 yt-dlp: yt-dlp "B站视频URL"
///
/// 示例API调用：
/// - 视频信息: https://api.bilibili.com/x/web-interface/view?bvid=BV号
/// - 视频流: https://api.bilibili.com/x/player/playurl?bvid=BV号&qn=80
class BilibiliParserService {
  BilibiliParserService._();

  static final BilibiliParserService _instance = BilibiliParserService._();

  factory BilibiliParserService() => _instance;

  /// 解析B站视频（需要配合后端或使用yt-dlp）
  Future<VideoInfo?> parseBilibiliVideo(String url) async {
    // 实际实现需要：
    // 1. 提取BV号
    // 2. 调用B站API获取视频信息
    // 3. 获取视频流URL
    // 4. 由于B站有防盗链和签名，建议使用后端服务处理

    return null;
  }
}

/// 统一的视频解析器
class UnifiedVideoParser {
  static final YouTubeParserService _youtube = YouTubeParserService();
  static final TikTokParserService _tiktok = TikTokParserService();

  /// 自动识别并解析视频
  static Future<VideoInfo?> parse(String url) async {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return await _youtube.parseYouTubeVideo(url);
    } else if (url.contains('douyin.com') || url.contains('tiktok.com')) {
      return await _tiktok.parseVideo(url);
    } else if (url.contains('bilibili.com') || url.contains('b23.tv')) {
      return await BilibiliParserService().parseBilibiliVideo(url);
    }

    return null;
  }

  /// 判断是否支持该平台
  static bool isSupported(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('douyin.com') ||
        url.contains('tiktok.com') ||
        url.contains('bilibili.com') ||
        url.contains('b23.tv');
  }
}
