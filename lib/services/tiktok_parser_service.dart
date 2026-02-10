import 'package:dio/dio.dart';
import 'package:calculator_app/models/video_info.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// TikTok/抖音视频解析服务
/// 使用第三方API进行解析
class TikTokParserService {
  TikTokParserService._();

  static final TikTokParserService _instance = TikTokParserService._();

  factory TikTokParserService() => _instance;

  final Dio _dio = Dio();

  /// API配置
  // 主API: TikWM API (免费，无需注册)
  static const String _tikwmApi = 'https://www.tikwm.com/api/';

  // 备用API列表（注意：这些API可能不稳定，建议定期更新）
  static const List<Map<String, String>> _backupApis = [
    {
      'name': 'OGeek',
      'url': 'https://api.oick.cn/douyin/api.php',
      'type': 'GET',
    },
    {
      'name': 'XiaoBing',
      'url': 'https://api.xingping.vip/api/douyin.php',
      'type': 'GET',
    },
    {
      'name': 'QuickSo',
      'url': 'https://api.quickso.cn/api/douyin',
      'type': 'GET',
    },
    {
      'name': 'TikWM (Backup)',
      'url': 'https://tikwm.com/api/',
      'type': 'GET',
    },
  ];

  // 自定义API（可以替换为其他服务）
  String? _customApiEndpoint;
  String? _customApiKey;

  /// 设置自定义API
  void setCustomApi(String endpoint, {String? apiKey}) {
    _customApiEndpoint = endpoint;
    _customApiKey = apiKey;
  }

  /// 解析TikTok/抖音视频
  Future<VideoInfo?> parseVideo(String url) async {
    try {
      print('🎬 开始解析视频');
      print('原始URL: $url');

      // 清理URL
      final cleanedUrl = _cleanUrl(url);
      print('清理后URL: $cleanedUrl');

      // 检查是否为抖音链接
      if (cleanedUrl.contains('douyin.com') || cleanedUrl.contains('v.douyin') ||
          cleanedUrl.contains('iesdouyin')) {
        print('检测到抖音链接');

        // 策略1: 如果是短链接，尝试展开
        String targetUrl = cleanedUrl;
        if (cleanedUrl.contains('v.douyin')) {
          print('策略1: 尝试展开短链接');
          final expandedUrl = await _expandShortUrl(cleanedUrl);
          if (expandedUrl != null && expandedUrl != cleanedUrl) {
            print('✓ 短链接展开成功');
            targetUrl = expandedUrl;
          } else {
            print('⚠️ 短链接展开失败，使用原链接');
          }
        }

        // 策略2: 尝试所有可用的API（包括备用API）
        print('策略2: 尝试使用多个API解析');

        // 首先尝试主API (TikWM)
        VideoInfo? result = await _parseWithTikWM(targetUrl);
        if (result != null) {
          print('✓ 主API解析成功');
          return result;
        }
        print('⚠️ 主API解析失败');

        // 尝试备用API
        for (var api in _backupApis) {
          print('尝试备用API: ${api['name']}');
          result = await _parseWithBackupApi(targetUrl, api);
          if (result != null) {
            print('✓ ${api['name']} 解析成功');
            return result;
          }
          print('⚠️ ${api['name']} 解析失败');
        }

        // 策略3: 尝试HTML爬虫解析（最后的后备方案）
        print('策略3: 尝试HTML爬虫解析');
        result = await _parseWithHtmlScraper(cleanedUrl);
        if (result != null) {
          print('✓ HTML爬虫解析成功');
          return result;
        }
        print('⚠️ HTML爬虫解析失败');

        // 所有策略都失败
        print('❌ 所有解析策略都失败');
        print('');
        print('📱 使用建议:');
        print('   1. 确保链接是从抖音App最新复制的');
        print('   2. 尝试分享到微信后再复制链接');
        print('   3. 或使用网页版链接: https://www.douyin.com/video/视频ID');
        print('   4. 检查网络连接是否正常');

        return null;
      }

      // TikTok链接
      print('检测到TikTok链接');
      VideoInfo? result = await _parseWithTikWM(cleanedUrl);
      if (result != null) {
        return result;
      }

      // 尝试备用API
      for (var api in _backupApis) {
        print('尝试备用API: ${api['name']}');
        result = await _parseWithBackupApi(cleanedUrl, api);
        if (result != null) {
          return result;
        }
      }

      return null;
    } catch (e) {
      print('❌ 解析异常: $e');
      return null;
    }
  }

  /// 清理URL，去除额外的字符和分享文本
  String _cleanUrl(String url) {
    // 去除前后空格
    url = url.trim();

    // 如果包含换行符，提取第一行
    if (url.contains('\n')) {
      final lines = url.split('\n');
      for (var line in lines) {
        if (line.contains('http')) {
          url = line;
          break;
        }
      }
    }

    // 使用正则表达式提取URL
    final urlPattern = RegExp(
      r'https?://[^\s\u4e00-\u9fff]+',
      caseSensitive: false,
    );

    final match = urlPattern.firstMatch(url);
    if (match != null) {
      url = match.group(0)!;
    }

    // 去除末尾的斜杠和其他字符
    url = url.replaceAll(RegExp(r'[/\\s]*$'), '');

    return url;
  }

  /// 清理抖音URL，移除所有查询参数，只保留视频ID
  String _cleanDouyinUrl(String url) {
    // 提取视频ID
    final videoIdPattern = RegExp(r'/video/(\d+)');
    final match = videoIdPattern.firstMatch(url);

    if (match != null && match.group(1) != null) {
      final videoId = match.group(1)!;
      // 返回干净的URL
      return 'https://www.douyin.com/video/$videoId';
    }

    // 如果没有视频ID，返回清理后的基础URL
    final cleanUrl = _cleanUrl(url);
    if (cleanUrl.contains('?')) {
      return cleanUrl.substring(0, cleanUrl.indexOf('?'));
    }

    return cleanUrl;
  }

  /// 使用TikWM API解析
  Future<VideoInfo?> _parseWithTikWM(String url) async {
    try {
      // 处理短链接 - 如果是抖音短链接，先展开
      String finalUrl = url;
      if (url.contains('v.douyin.com') || url.contains('www.iesdouyin.com')) {
        final expandedUrl = await _expandShortUrl(url);
        if (expandedUrl != null) {
          finalUrl = expandedUrl;
          print('抖音短链接已展开: $finalUrl');
        }
      }

      // 清理抖音URL - 移除所有查询参数
      if (finalUrl.contains('douyin.com') || finalUrl.contains('iesdouyin.com')) {
        finalUrl = _cleanDouyinUrl(finalUrl);
        print('已清理抖音URL参数: $finalUrl');
      }

      print('开始解析抖音/TikTok链接: $finalUrl');

      final response = await _dio.get(
        _tikwmApi,
        queryParameters: {
          'url': finalUrl,
          'hd': 1, // 获取高清视频
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('API响应状态: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        print('API响应数据: $data');

        // TikWM API响应格式
        if (data['code'] == 0 && data['data'] != null) {
          final videoData = data['data'];

          // 确定平台
          final platform = url.contains('douyin.com') ||
                  url.contains('iesdouyin.com') ||
                  url.contains('v.douyin.com')
              ? 'douyin'
              : 'tiktok';

          // 获取视频URL（优先无水印）
          String videoUrl = videoData['play'] ??
              videoData['wmplay'] ??
              videoData['music'] ??
              '';
          String coverUrl = videoData['cover'] ??
              videoData['origin_cover'] ??
              videoData['thumbnail'] ??
              '';

          // 如果没有视频URL，尝试从play_addr获取
          if (videoUrl.isEmpty && videoData['play_addr'] != null) {
            final playAddr = videoData['play_addr'];
            if (playAddr is List && playAddr.isNotEmpty) {
              videoUrl = playAddr[0]['url'] ?? '';
            }
          }

          // 如果还是没有，尝试其他字段
          if (videoUrl.isEmpty) {
            videoUrl = videoData['video_url'] ?? '';
          }

          print('视频URL: $videoUrl');
          print('封面URL: $coverUrl');

          // 获取作者信息
          final authorData = videoData['author'] ?? {};
          final author = authorData['nickname'] ??
              authorData['unique_id'] ??
              authorData['nickname'] ??
              '未知作者';

          // 获取时长（抖音可能没有duration字段）
          int? duration = videoData['duration'];
          if (duration == null && videoData['video'] != null) {
            duration = videoData['video']['duration'];
          }

          // 提取图片列表
          final List<ImageInfo> images = _extractImages(videoData);

          return VideoInfo(
            id: videoData['id'] ??
                videoData['aweme_id'] ??
                'tiktok_${DateTime.now().millisecondsSinceEpoch}',
            title: videoData['title'] ??
                videoData['desc'] ??
                videoData['description'] ??
                'TikTok视频',
            description: videoData['desc'] ??
                videoData['description'] ??
                videoData['text'] ??
                '',
            coverUrl: coverUrl,
            videoUrl: videoUrl,
            author: author,
            platform: platform,
            duration: duration != null ? (duration * 1000).toInt() : null,
            images: images,
          );
        } else {
          print('API返回错误: ${data['msg'] ?? data['message']}');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('TikWM API请求失败: $e');
      return null;
    }
  }

  /// 使用自定义API解析
  Future<VideoInfo?> _parseWithCustomApi(String url) async {
    try {
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          if (_customApiKey != null) 'Authorization': 'Bearer $_customApiKey',
        },
      );

      final response = await _dio.post(
        _customApiEndpoint!,
        data: {'url': url},
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        // 根据自定义API的响应格式解析
        // 这里提供一个通用的解析逻辑，可以根据实际API调整
        final data = response.data;

        if (data['code'] == 0 || data['success'] == true) {
          final videoData = data['data'];

          // 提取图片列表
          final List<ImageInfo> images = _extractImages(videoData);

          return VideoInfo(
            id: videoData['id'] ?? '',
            title: videoData['title'] ?? videoData['desc'] ?? '',
            description: videoData['description'] ?? videoData['desc'] ?? '',
            coverUrl: videoData['cover'] ?? videoData['thumbnail'] ?? '',
            videoUrl: videoData['url'] ?? videoData['videoUrl'] ?? '',
            author: videoData['author'] ?? videoData['authorName'] ?? '',
            platform: videoData['platform'],
            duration: videoData['duration'],
            images: images,
          );
        }
      }

      return null;
    } catch (e) {
      print('自定义API请求失败: $e');
      return null;
    }
  }

  /// 使用备用API解析
  Future<VideoInfo?> _parseWithBackupApi(String url, Map<String, String> api) async {
    try {
      final apiUrl = api['url']!;
      final apiType = api['type']!;
      final apiName = api['name']!;

      // 清理抖音URL
      String cleanUrl = url;
      if (url.contains('douyin.com') || url.contains('iesdouyin.com')) {
        cleanUrl = _cleanDouyinUrl(url);
        print('  清理后的URL: $cleanUrl');
      }

      print('  正在调用 $apiName API...');
      print('  API地址: $apiUrl');

      final response = apiType == 'GET'
          ? await _dio.get(
              apiUrl,
              queryParameters: {'url': cleanUrl},
              options: Options(
                headers: {
                  'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
                },
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
                validateStatus: (status) => status != null && status < 500,
              ),
            )
          : await _dio.post(
              apiUrl,
              data: {'url': cleanUrl},
              options: Options(
                headers: {
                  'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
                },
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
                validateStatus: (status) => status != null && status < 500,
              ),
            );

      print('  $apiName 响应状态: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('  $apiName 响应数据: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');

        // 尝试从不同API格式中提取数据
        Map<String, dynamic>? videoData;

        // TikWM 格式
        if (data['code'] == 0 && data['data'] != null) {
          videoData = data['data'];
        }
        // OGeek/XiaoBing 格式 (code: 1 表示成功)
        else if (data['code'] == 1 && data['data'] != null) {
          videoData = data['data'];
        }
        // 直接返回视频数据的格式
        else if (data['url'] != null || data['video_url'] != null) {
          videoData = data;
        }
        // QuickSo 等其他格式
        else if (data['data'] != null) {
          videoData = data['data'];
        }

        if (videoData != null) {
          final platform = url.contains('douyin') ||
                  url.contains('iesdouyin') ||
                  url.contains('v.douyin')
              ? 'douyin'
              : 'tiktok';

          // 提取视频URL（尝试多个字段）
          String videoUrl = videoData['url'] ??
              videoData['video_url'] ??
              videoData['play'] ??
              videoData['download_url'] ??
              videoData['hdplay'] ??
              '';

          // 提取封面
          String coverUrl = videoData['cover'] ??
              videoData['pic'] ??
              videoData['origin_cover'] ??
              videoData['thumbnail'] ??
              videoData['cover_url'] ??
              '';

          // 提取标题
          String title = videoData['title'] ??
              videoData['desc'] ??
              videoData['text'] ??
              videoData['description'] ??
              '$platform视频';

          // 提取作者
          String author = '未知作者';
          if (videoData['author'] != null) {
            if (videoData['author'] is Map) {
              author = videoData['author']['nickname'] ??
                  videoData['author']['unique_id'] ??
                  '未知作者';
            } else if (videoData['author'] is String) {
              author = videoData['author'];
            }
          }
          author = videoData['author_name'] ?? videoData['nickname'] ?? author;

          if (videoUrl.isNotEmpty) {
            print('  ✓ $apiName 成功获取视频信息');

            // 提取图片列表
          final List<ImageInfo> images = _extractImages(videoData);

          return VideoInfo(
              id: videoData['id'] ??
                  videoData['aweme_id'] ??
                  videoData['video_id'] ??
                  '${platform}_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              description: videoData['desc'] ??
                  videoData['description'] ??
                  videoData['text'] ??
                  '',
              coverUrl: coverUrl,
              videoUrl: videoUrl,
              author: author,
              platform: platform,
              duration: videoData['duration'] != null
                  ? (videoData['duration'] * 1000).toInt()
                  : null,
              images: images,
            );
          } else {
            print('  ⚠️ $apiName 返回数据中未找到视频URL');
          }
        }
      }

      return null;
    } catch (e) {
      print('  ⚠️ ${api['name']} API请求失败: $e');
      return null;
    }
  }

  /// 使用HTML爬虫解析（后备方案）
  /// 直接抓取抖音网页并提取视频信息
  Future<VideoInfo?> _parseWithHtmlScraper(String url) async {
    try {
      print('  开始HTML爬虫解析...');

      // 清理URL
      String cleanUrl = url;
      if (url.contains('douyin.com') || url.contains('iesdouyin.com')) {
        cleanUrl = _cleanDouyinUrl(url);
      }

      print('  抓取网页: $cleanUrl');

      final response = await _dio.get(
        cleanUrl,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Referer': 'https://www.douyin.com/',
          },
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 15),
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          maxRedirects: 10,
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        print('  ⚠️ 无法获取网页内容');
        return null;
      }

      print('  ✓ 网页抓取成功');

      // 解析HTML
      final document = html_parser.parse(response.data);

      // 尝试从页面中提取视频数据（多种格式）
      String? videoUrl;
      String? coverUrl;
      String? title;
      String? author;
      String? videoId;

      // 方法1: 从script标签中提取JSON数据
      final scripts = document.getElementsByTagName('script');
      for (var script in scripts) {
        final text = script.text;
        if (text.contains('videoUrl') || text.contains('playAddr')) {
          // 尝试提取视频URL
          final videoUrlMatch = RegExp(r'"playAddr":"([^"]+)"').firstMatch(text);
          if (videoUrlMatch != null && videoUrlMatch.group(1) != null) {
            videoUrl = videoUrlMatch.group(1)!.replaceAll('\\u002F', '/');
            break;
          }

          final urlMatch = RegExp(r'"url":"([^"]+\.mp3[^"]*)"').firstMatch(text);
          if (urlMatch != null && urlMatch.group(1) != null) {
            videoUrl = urlMatch.group(1)!.replaceAll('\\u002F', '/');
            break;
          }
        }
      }

      // 方法2: 从meta标签提取
      if (videoUrl == null || videoUrl.isEmpty) {
        final videoMeta = document.querySelector('meta[property="og:video"]');
        if (videoMeta != null) {
          videoUrl = videoMeta.attributes['content'];
        }
      }

      // 提取封面
      final imageMeta = document.querySelector('meta[property="og:image"]');
      if (imageMeta != null) {
        coverUrl = imageMeta.attributes['content'];
      }

      // 提取标题
      final titleMeta = document.querySelector('meta[property="og:title"]');
      if (titleMeta != null) {
        title = titleMeta.attributes['content'];
      }

      // 提取视频ID
      final idMatch = RegExp(r'/video/(\d+)').firstMatch(cleanUrl);
      if (idMatch != null && idMatch.group(1) != null) {
        videoId = idMatch.group(1);
      }

      if (videoUrl != null && videoUrl.isNotEmpty) {
        print('  ✓ HTML爬虫成功提取视频URL');

        // 尝试从HTML中提取图片（如果有）
        final List<ImageInfo> images = [];
        if (coverUrl != null && coverUrl.isNotEmpty) {
          images.add(ImageInfo(url: coverUrl));
        }

        return VideoInfo(
          id: videoId ?? 'douyin_${DateTime.now().millisecondsSinceEpoch}',
          title: title ?? '抖音视频',
          description: '通过HTML爬虫解析',
          coverUrl: coverUrl ?? '',
          videoUrl: videoUrl,
          author: author ?? '未知作者',
          platform: 'douyin',
          duration: null,
          images: images,
        );
      }

      print('  ⚠️ HTML爬虫未能提取到视频URL');
      return null;
    } catch (e) {
      print('  ⚠️ HTML爬虫解析失败: $e');
      return null;
    }
  }

  /// 批量解析多个视频
  Future<List<VideoInfo>> parseMultiple(List<String> urls) async {
    final results = <VideoInfo>[];

    for (final url in urls) {
      final videoInfo = await parseVideo(url);
      if (videoInfo != null) {
        results.add(videoInfo);
      }

      // 避免请求过快
      if (urls.length > 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }

  /// 从分享文本中提取视频URL
  String? extractVideoUrl(String text) {
    // TikTok URL模式
    final tiktokPattern = RegExp(
      r'https?://(www\.)?(tiktok\.com|vm\.tiktok\.com|vt\.tiktok\.com)/[\w\-/?=.&]+',
    );

    // 抖音 URL模式
    final douyinPattern = RegExp(
      r'https?://(www\.)?(douyin\.com|v\.douyin\.com|iesdouyin\.com)/[\w\-/?=.&]+',
    );

    // 优先匹配TikTok
    final tiktokMatch = tiktokPattern.firstMatch(text);
    if (tiktokMatch != null) {
      return tiktokMatch.group(0);
    }

    // 匹配抖音
    final douyinMatch = douyinPattern.firstMatch(text);
    if (douyinMatch != null) {
      return douyinMatch.group(0);
    }

    return null;
  }

  /// 检查URL是否有效
  bool isValidUrl(String url) {
    return url.contains('tiktok.com') ||
        url.contains('douyin.com') ||
        url.contains('iesdouyin.com');
  }

  /// 从API数据中提取图片列表
  List<ImageInfo> _extractImages(Map<String, dynamic> videoData) {
    final List<ImageInfo> images = [];

    try {
      // 方法1: 从 images 字段直接获取
      if (videoData['images'] != null) {
        final imagesList = videoData['images'];
        if (imagesList is List) {
          for (var img in imagesList) {
            // 处理不同类型的图片数据
            if (img is String && img.isNotEmpty) {
              // 字符串类型的URL
              images.add(ImageInfo(url: img));
            } else if (img is Map) {
              // 对象类型的图片数据
              final url = img['url'] ?? img['cover_url'] ?? img['cover'];
              if (url != null && url.isNotEmpty) {
                images.add(ImageInfo(url: url));
              }
            }
          }
        }
      }

      // 方法2: 从 music_cover 获取
      if (images.isEmpty && videoData['music_cover'] != null) {
        final musicCover = videoData['music_cover'];
        if (musicCover is String && musicCover.isNotEmpty) {
          images.add(ImageInfo(url: musicCover));
        }
      }

      // 方法3: 从 static_cover 获取
      if (images.isEmpty && videoData['static_cover'] != null) {
        final staticCover = videoData['static_cover'];
        if (staticCover is String && staticCover.isNotEmpty) {
          images.add(ImageInfo(url: staticCover));
        }
      }

      // 方法4: 从 dynamic_cover 获取
      if (images.isEmpty && videoData['dynamic_cover'] != null) {
        final dynamicCover = videoData['dynamic_cover'];
        if (dynamicCover is Map && dynamicCover['url_list'] != null) {
          final urlList = dynamicCover['url_list'];
          if (urlList is List) {
            for (var item in urlList) {
              if (item is String && item.isNotEmpty) {
                images.add(ImageInfo(url: item));
              }
            }
          }
        }
      }

      // 方法5: 从 avatar 获取作者头像
      if (videoData['author'] != null) {
        final author = videoData['author'];
        if (author is Map && author['avatar_thumb'] != null) {
          images.add(ImageInfo(url: author['avatar_thumb']));
        }
      }

      // 方法6: 从 avatar 字段直接获取
      if (images.isEmpty && videoData['avatar'] != null) {
        final avatar = videoData['avatar'];
        if (avatar is String && avatar.isNotEmpty) {
          images.add(ImageInfo(url: avatar));
        }
      }

      // 方法7: 从 cover 获取封面
      if (images.isEmpty && videoData['cover'] != null) {
        final cover = videoData['cover'];
        if (cover is String && cover.isNotEmpty) {
          images.add(ImageInfo(url: cover));
        }
      }

      print('📸 提取到 ${images.length} 张图片');
    } catch (e) {
      print('⚠️ 提取图片失败: $e');
    }

    return images;
  }

  /// 获取API使用情况（TikWM）
  Future<Map<String, dynamic>> getApiUsage() async {
    // TikWM不提供使用情况查询
    // 如果使用自定义API，可以在这里实现
    return {
      'api': 'TikWM',
      'type': '免费',
      'limit': '每天100次请求',
      'status': 'active',
    };
  }

  /// 展开短链接
  Future<String?> _expandShortUrl(String shortUrl) async {
    print('🔍 尝试展开短链接: $shortUrl');

    // 方法1: 使用HEAD请求（不跟随重定向）
    try {
      print('  方法1: HEAD请求');
      final response = await _dio.head(
        shortUrl,
        options: Options(
          followRedirects: false,
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          },
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // 检查Location头（可能返回301/302/307/308）
      if (response.statusCode == 301 || response.statusCode == 302 ||
          response.statusCode == 307 || response.statusCode == 308) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          final redirectUrl = location is List ? location.first : location;
          final urlString = redirectUrl.toString();

          // 如果是相对路径，转换为绝对路径
          if (urlString.startsWith('/')) {
            final uri = Uri.parse(shortUrl);
            return '${uri.scheme}://${uri.host}$urlString';
          }

          print('  ✓ HEAD方法成功: $urlString');
          return urlString;
        }
      }

      print('  ⚠️ HEAD响应无Location头或状态码: ${response.statusCode}');
    } catch (e) {
      print('  ⚠️ HEAD方法失败: $e');
    }

    // 方法2: 使用GET请求跟随重定向
    try {
      print('  方法2: GET请求跟随重定向');
      final response = await _dio.get(
        shortUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          },
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final finalUrl = response.realUri.toString();
      if (finalUrl != shortUrl && (finalUrl.contains('douyin.com') || finalUrl.contains('aweme'))) {
        print('  ✓ GET方法成功: $finalUrl');
        return finalUrl;
      }

      print('  ⚠️ GET方法未获得有效重定向URL: $finalUrl');
    } catch (e) {
      print('  ⚠️ GET方法失败: $e');
    }

    // 方法3: 使用真实的浏览器User-Agent尝试
    try {
      print('  方法3: 桌面浏览器User-Agent');
      final response = await _dio.get(
        shortUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Referer': 'https://www.douyin.com/',
          },
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final finalUrl = response.realUri.toString();
      if (finalUrl != shortUrl) {
        print('  ✓ 桌面UA方法成功: $finalUrl');
        return finalUrl;
      }
    } catch (e) {
      print('  ⚠️ 桌面UA方法失败: $e');
    }

    // 方法4: 使用安卓抖音App内嵌浏览器UA
    try {
      print('  方法4: 抖音App内嵌UA');
      final response = await _dio.get(
        shortUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          headers: {
            'User-Agent': 'com.ss.android.ugc.aweme/280102 (Linux; U; Android 13; zh_CN; 2211133C; Build/TQ2A.230405.003.C4; Cronet/TTNetVersion:6c7b701a 2021-08-10 QuicVersion:0144d358 2021-07-28)',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final finalUrl = response.realUri.toString();
      if (finalUrl != shortUrl) {
        print('  ✓ 抖音UA方法成功: $finalUrl');
        return finalUrl;
      }
    } catch (e) {
      print('  ⚠️ 抖音UA方法失败: $e');
    }

    print('  ❌ 所有的展开方法都失败');
    print('  💡 提示: 短链接可能有防爬虫保护，建议直接复制抖音App内的完整链接');
    return null;
  }

  /// 直接使用TikWM API（支持短链接）
  /// TikWM API 可以自动处理抖音和TikTok的短链接
  Future<VideoInfo?> parseDirectly(String url) async {
    try {
      print('🎬 直接使用TikWM API解析: $url');

      // 清理URL
      String cleanedUrl = _cleanUrl(url);
      print('📍 清理后URL: $cleanedUrl');

      // 如果是短链接，先尝试展开
      String finalUrl = cleanedUrl;
      if (cleanedUrl.contains('v.douyin.com') || cleanedUrl.contains('douyin.com')) {
        print('检测到抖音链接，先尝试展开短链接...');
        final expandedUrl = await _expandShortUrl(cleanedUrl);
        if (expandedUrl != null && expandedUrl != cleanedUrl) {
          finalUrl = expandedUrl;
          print('✓ 短链接已展开，使用展开后的URL');
        } else {
          print('⚠️ 短链接展开失败，尝试直接解析原链接');
        }

        // 清理抖音URL - 移除所有查询参数
        finalUrl = _cleanDouyinUrl(finalUrl);
        print('📍 清理后的URL: $finalUrl');
      }

      print('📍 最终解析URL: $finalUrl');

      final response = await _dio.get(
        _tikwmApi,
        queryParameters: {
          'url': finalUrl,
          'hd': 1,
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('📡 API响应状态: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('📦 TikWM API响应: $data');

        if (data['code'] == 0 && data['data'] != null) {
          final videoData = data['data'];

          final platform = url.contains('douyin') ||
                  url.contains('iesdouyin') ||
                  url.contains('v.douyin')
              ? 'douyin'
              : 'tiktok';

          print('✓ API返回成功，平台: $platform');

          // 尝试多种字段获取视频URL
          String videoUrl = videoData['play'] ??
              videoData['wmplay'] ??
              videoData['hdplay'] ??
              videoData['music'] ??
              '';

          // 如果还是没有，从play_addr获取
          if (videoUrl.isEmpty && videoData['play_addr'] != null) {
            final playAddr = videoData['play_addr'];
            if (playAddr is List && playAddr.isNotEmpty) {
              videoUrl = playAddr[0]['url'] ??
                  playAddr[0]['uri'] ?? '';
            }
          }

          // 最后尝试 video_url 字段
          if (videoUrl.isEmpty) {
            videoUrl = videoData['video_url'] ?? '';
          }

          print('🎬 最终视频URL: $videoUrl');

          if (videoUrl.isEmpty) {
            print('❌ 未能获取视频URL');
            print('📋 完整响应数据: ${videoData.toString()}');
            return null;
          }

          // 获取封面
          String coverUrl = videoData['cover'] ??
              videoData['origin_cover'] ??
              videoData['dynamic_cover'] ??
              videoData['thumbnail'] ??
              '';

          // 获取作者
          final authorData = videoData['author'] ?? {};
          final author = authorData['nickname'] ??
              authorData['unique_id'] ??
              authorData['nickname'] ??
              '未知作者';

          // 提取图片列表
          final List<ImageInfo> images = _extractImages(videoData);

          return VideoInfo(
            id: videoData['id'] ??
                videoData['aweme_id'] ??
                videoData['video_id'] ??
                'douyin_${DateTime.now().millisecondsSinceEpoch}',
            title: videoData['title'] ??
                videoData['desc'] ??
                videoData['description'] ??
                videoData['text'] ??
                '抖音视频',
            description: videoData['desc'] ??
                videoData['description'] ??
                videoData['text'] ??
                '',
            coverUrl: coverUrl,
            videoUrl: videoUrl,
            author: author,
            platform: platform,
            duration: videoData['duration'] != null
                ? (videoData['duration'] * 1000).toInt()
                : null,
            images: images,
          );
        } else {
          print('❌ API返回错误: code=${data['code']}, msg=${data['msg']}');
          if (cleanedUrl.contains('v.douyin')) {
            print('');
            print('💡 短链接解析失败建议:');
            print('   1. 确保链接是最新从抖音App复制的');
            print('   2. 尝试在抖音App中分享到微信后复制链接');
            print('   3. 使用抖音网页版链接 (https://www.douyin.com/video/...)');
          }
          return null;
        }
      }

      return null;
    } catch (e) {
      print('❌ 直接解析失败: $e');
      return null;
    }
  }
}
