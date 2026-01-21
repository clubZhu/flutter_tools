# TikTok/抖音视频解析集成说明

## 已集成功能

✅ **TikTok/抖音解析已完全集成**

本应用使用 [TikWM API](https://tikwm.com/) 进行TikTok和抖音视频解析，**无需注册，完全免费**。

---

## 支持的链接格式

### TikTok
- `https://www.tiktok.com/@user/video/1234567890123456789`
- `https://vm.tiktok.com/ZMxxxxxxx/`
- `https://vt.tiktok.com/ZMxxxxxxx/`

### 抖音
- `https://www.douyin.com/video/1234567890123456789`
- `https://v.douyin.com/xxxxx/`
- `https://www.iesdouyin.com/share/video/1234567890123456789`

---

## 使用方法

### 1. 基本使用（通过UI）

1. 打开应用，点击"视频下载"按钮
2. 粘贴TikTok或抖音分享链接
3. 点击"解析视频"
4. 等待解析完成，查看视频信息
5. 点击"下载视频"保存到本地

### 2. 代码中使用

#### 解析单个视频
```dart
import 'package:calculator_app/services/tiktok_parser_service.dart';

final parser = TikTokParserService();

// TikTok链接
final tiktokUrl = 'https://www.tiktok.com/@user/video/1234567890';
final videoInfo = await parser.parseVideo(tiktokUrl);

if (videoInfo != null) {
  print('标题: ${videoInfo.title}');
  print('作者: ${videoInfo.author}');
  print('视频地址: ${videoInfo.videoUrl}');
  print('封面: ${videoInfo.coverUrl}');
}
```

#### 从分享文本中提取URL
```dart
final shareText = '''
快来围观这个视频！ https://v.douyin.com/jkF8xY/
已经火爆全网！
''';

final url = parser.extractVideoUrl(shareText);
if (url != null) {
  final videoInfo = await parser.parseVideo(url);
  // 处理视频信息
}
```

#### 批量解析
```dart
final urls = [
  'https://www.tiktok.com/@user1/video/123',
  'https://v.douyin.com/abc/',
  'https://www.tiktok.com/@user2/video/456',
];

final results = await parser.parseMultiple(urls);
for (final video in results) {
  print('${video.title} - ${video.author}');
}
```

#### 下载视频
```dart
import 'package:calculator_app/services/video_download_service.dart';

final downloadService = VideoDownloadService();

// 1. 解析视频
final videoInfo = await downloadService.parseVideoUrl(url);

if (videoInfo != null) {
  // 2. 下载视频
  final file = await downloadService.downloadVideo(
    videoInfo.videoUrl,
    'video_${videoInfo.id}.mp4',
    onProgress: (received, total) {
      final progress = (received / total * 100).toStringAsFixed(1);
      print('下载进度: $progress%');
    },
  );

  if (file != null) {
    print('下载完成: ${file.path}');
  }
}
```

---

## API配置

### 使用默认TikWM API（推荐）
```dart
// 无需配置，开箱即用
final parser = TikTokParserService();
final videoInfo = await parser.parseVideo(url);
```

### 使用自定义API
如果你的TikWM API有使用限制，可以配置其他API服务：

```dart
final parser = TikTokParserService();

// 设置自定义API端点
parser.setCustomApi(
  'https://your-api.com/video/parse',
  apiKey: 'your_api_key', // 可选
);

// 使用自定义API解析
final videoInfo = await parser.parseVideo(url);
```

---

## API信息

### TikWM API（默认）
- **官网**: https://tikwm.com/
- **费用**: 免费（每天100次请求）
- **响应速度**: 快（1-3秒）
- **支持**: TikTok、抖音无水印视频
- **无需注册**: 可直接使用

### API限制
- 免费版：每天100次请求
- 单次请求响应时间：最多30秒
- 建议控制请求频率，避免被限流

---

## 功能特性

### ✅ 已实现
- [x] 解析TikTok视频链接
- [x] 解析抖音视频链接
- [x] 获取视频标题、描述
- [x] 获取作者信息
- [x] 获取封面图片
- [x] 获取无水印视频下载链接
- [x] 自动识别平台
- [x] 从分享文本提取URL
- [x] 批量解析支持
- [x] 错误处理和提示

### 🔄 可扩展
- [ ] 支持更多视频清晰度选择
- [ ] 支持评论解析
- [ ] 支持音乐提取
- [ ] 支持历史记录

---

## 常见问题

### Q: 解析失败怎么办？
**A**: 可能的原因和解决方法：
1. **链接无效** - 检查链接是否正确，尝试重新复制
2. **视频已删除** - 原视频可能已被作者删除
3. **API限流** - 等待一段时间后重试
4. **网络问题** - 检查网络连接

### Q: 下载速度慢？
**A**:
- TikWM API返回的是原始视频链接
- 下载速度取决于视频服务器位置
- 建议在WiFi环境下下载

### Q: 无法下载某些视频？
**A**:
- 部分视频可能有地区限制
- 私密视频无法解析
- 版权受限视频可能无法下载

### Q: 如何取消下载？
**A**:
在下载页面点击"取消下载"按钮即可

---

## 测试链接

### TikTok
```
https://www.tiktok.com/@scout2015/video/6718335390845095173
https://vm.tiktok.com/ZMJMxnqkh/
```

### 抖音
```
https://www.douyin.com/video/7123456789012345678
https://v.douyin.com/jkF8xY/
```

---

## 注意事项

⚠️ **重要提示**:

1. **版权保护**: 下载视频仅供个人学习使用，请勿用于商业用途
2. **作者权益**: 传播视频时请保留原作者信息
3. **合法使用**: 遵守当地法律法规和平台使用条款
4. **API限制**: 注意API使用频率，避免过度请求

---

## 更新日志

### v1.0.0 (2024-01-20)
- ✅ 集成TikWM API
- ✅ 支持TikTok/抖音解析
- ✅ 实现无水印视频下载
- ✅ 添加UI界面
- ✅ 完善错误处理

---

## 技术支持

如有问题，请检查：
1. 链接格式是否正确
2. 网络连接是否正常
3. API服务是否可用
4. 应用是否有足够权限

---

## 相关资源

- **TikWM API**: https://tikwm.com/api.html
- **TikWM官网**: https://tikwm.com/
- **抖音开放平台**: https://developer.open-douyin.com/
- **TikTok for Developers**: https://developers.tiktok.com/
