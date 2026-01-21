# 视频解析库和API使用指南

本项目已集成视频解析功能，支持多个主流视频平台。

## 已集成的解析库

### 1. YouTube - youtube_explode_dart

**状态**: ✅ 已完全支持

**功能**:
- 解析YouTube视频链接
- 获取视频标题、描述、封面等信息
- 获取不同清晰度的视频流
- 搜索YouTube视频

**使用示例**:
```dart
import 'package:calculator_app/services/video_parser_service.dart';

// 解析单个视频
final videoInfo = await YouTubeParserService().parseYouTubeVideo(
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
);

// 获取所有可用的视频流
final streams = await YouTubeParserService().getVideoStreams(url);

// 搜索视频
final results = await YouTubeParserService().searchVideos('flutter tutorial');
```

**文档**: https://github.com/Hexer10/youtube_explode_dart

---

## 需要第三方API的平台

### 2. TikTok / 抖音

**状态**: ⚠️ 需要对接第三方API

**推荐方案**:

#### 方案A: TikWM API (推荐)
- **官网**: https://tikwm.com/
- **文档**: https://tikwm.com/api.html
- **免费额度**: 每天100次请求
- **响应速度**: 快

**API调用示例**:
```dart
import 'package:dio/dio.dart';

Future<VideoInfo?> parseTikTokWithTikWM(String url) async {
  final dio = Dio();
  final response = await dio.get(
    'https://www.tikwm.com/api/',
    queryParameters: {'url': url},
    // 如果有API密钥
    // options: Options(headers: {'Authorization': 'YOUR_API_KEY'})
  );

  if (response.statusCode == 200 && response.data['code'] == 0) {
    final data = response.data['data'];
    return VideoInfo(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      coverUrl: data['cover'],
      videoUrl: data['play'], // 无水印视频链接
      author: data['author']['nickname'],
      platform: url.contains('douyin') ? 'douyin' : 'tiktok',
      duration: (data['duration'] * 1000).toInt(),
    );
  }
  return null;
}
```

#### 方案B: 自建后端服务
使用 Node.js + Puppeteer 或 Python + yt-dlp

**Python示例**:
```python
import yt_dlp

def get_tiktok_video(url):
    ydl_opts = {
        'format': 'best',
        'quiet': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        return {
            'title': info['title'],
            'url': info['url'],
            'thumbnail': info['thumbnail'],
            'author': info['uploader'],
        }
```

---

### 3. B站 (Bilibili)

**状态**: ⚠️ 需要特殊处理

**挑战**:
- B站有防盗链
- 视频URL有签名验证
- 需要登录才能访问某些视频

**推荐方案**:

#### 方案A: 使用 yt-dlp (Python)
```bash
yt-dlp "B站视频URL" --get-url
```

#### 方案B: 使用第三方API服务
- Olevod API
- JiShu API

#### 方案C: 自建后端
使用 Python + you-get 或 yt-dlp

---

### 4. 其他平台

#### 微博
- API限制较多
- 建议使用第三方API服务

#### 快手
- 有加密机制
- 需要后端处理

---

## 使用统一的视频解析器

```dart
import 'package:calculator_app/services/video_parser_service.dart';

// 自动识别平台并解析
final videoInfo = await UnifiedVideoParser.parse(videoUrl);

if (videoInfo != null) {
  print('标题: ${videoInfo.title}');
  print('作者: ${videoInfo.author}');
  print('视频地址: ${videoInfo.videoUrl}');
}
```

---

## 在项目中使用

### 解析视频
```dart
final service = VideoDownloadService();
final videoInfo = await service.parseVideoUrl(videoUrl);

if (videoInfo != null) {
  // 显示视频信息
  // 预览视频
  // 下载视频
}
```

### 下载视频
```dart
final file = await service.downloadVideo(
  videoInfo.videoUrl,
  fileName,
  onProgress: (received, total) {
    final progress = received / total;
    print('下载进度: ${(progress * 100).toStringAsFixed(1)}%');
  },
);
```

---

## 注意事项

1. **YouTube**: 已完全支持，可直接使用
2. **TikTok/抖音**: 需要对接第三方API，推荐使用TikWM
3. **B站**: 建议使用后端服务处理，避免前端直接调用
4. **版权**: 使用时请遵守各平台的使用条款
5. **频率限制**: 注意API调用频率，避免被封禁

---

## 测试链接

### YouTube
- https://www.youtube.com/watch?v=dQw4w9WgXcQ
- https://youtu.be/dQw4w9WgXcQ

### TikTok
- https://www.tiktok.com/@user/video/123456789

### 抖音
- https://v.douyin.com/xxxxx/

### B站
- https://www.bilibili.com/video/BV1xx411c7mD

---

## 相关资源

### 库和工具
- [youtube_explode_dart](https://github.com/Hexer10/youtube_explode_dart) - YouTube解析
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - 通用视频下载工具
- [you-get](https://github.com/soimort/you-get) - 视频下载工具

### API服务
- [TikWM](https://tikwm.com/) - TikTok/抖音解析
- [Olevod](https://api.olevod.com) - 多平台视频解析

### 学习资源
- [Flutter网络请求](https://flutter.dev/docs/cookbook/networking)
- [Dio HTTP客户端](https://pub.dev/packages/dio)
