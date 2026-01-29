# 抖音视频解析完整修复方案

## 修复日期
2026-01-29 (v1.4)

## 问题诊断

### 根本原因
通过日志分析发现：
1. **TikWM API 不支持抖音链接** - 只支持TikTok
2. **备用API全部失效** - 302重定向、403禁止访问、DNS解析失败
3. **缺乏有效的抖音专用API**

### 日志证据
```
API响应数据: {code: -1, msg: Url parsing is failed! Please check url.}
⚠️ LoveTik API请求失败: Failed host lookup: 'api.lovetik.com'
⚠️ TikDown API请求失败: status code of 302
⚠️ SSSTik API请求失败: status code of 403
```

## 完整解决方案

### ✅ 1. 添加支持抖音的第三方API

更新后的备用API列表（真正支持抖音）：

```dart
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
```

**特点**：
- 专门针对抖音的API
- 支持多种响应格式（code: 0, code: 1等）
- 增强的错误处理（302、403等）

### ✅ 2. 实现HTML爬虫解析

添加了 `_parseWithHtmlScraper()` 方法作为最后的后备方案：

```dart
/// 使用HTML爬虫解析（后备方案）
/// 直接抓取抖音网页并提取视频信息
Future<VideoInfo?> _parseWithHtmlScraper(String url)
```

**功能**：
1. **直接抓取抖音网页**
   - 使用iPhone User-Agent
   - 跟随重定向
   - 获取完整HTML内容

2. **多种提取策略**
   - 从 `<script>` 标签提取JSON数据
   - 从 `<meta>` 标签提取OG数据
   - 正则表达式匹配视频URL

3. **提取内容**
   - 视频URL（playAddr、url等）
   - 封面图（og:image）
   - 标题（og:title）
   - 视频ID

### ✅ 3. 增强的数据提取

改进了 `_parseWithBackupApi()` 方法，支持更多API响应格式：

```dart
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
```

### ✅ 4. 三层降级策略

```
1. 主API (TikWM)
   ↓ 失败
2. 抖音专用备用API (OGeek, XiaoBing, QuickSo)
   ↓ 失败
3. HTML爬虫解析 (直接抓取网页)
   ↓ 失败
详细错误提示
```

### ✅ 5. 改进错误处理

```dart
validateStatus: (status) => status != null && status < 500,
```

- 不再因为302、403等状态码直接失败
- 尝试处理所有2xx-4xx状态码
- 更详细的错误日志

## 技术实现

### 导入HTML解析库
```dart
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
```

### HTML爬虫核心代码
```dart
// 解析HTML
final document = html_parser.parse(response.data);

// 方法1: 从script标签中提取JSON数据
final scripts = document.getElementsByTagName('script');
for (var script in scripts) {
  final text = script.text;
  if (text.contains('videoUrl') || text.contains('playAddr')) {
    final videoUrlMatch = RegExp(r'"playAddr":"([^"]+)"').firstMatch(text);
    if (videoUrlMatch != null) {
      videoUrl = videoUrlMatch.group(1)!.replaceAll('\\u002F', '/');
      break;
    }
  }
}

// 方法2: 从meta标签提取
final videoMeta = document.querySelector('meta[property="og:video"]');
if (videoMeta != null) {
  videoUrl = videoMeta.attributes['content'];
}
```

## API参考

根据搜索结果，以下是目前可用的抖音解析API：

1. **OGeek API**
   - 地址：`https://api.oick.cn/douyin/api.php`
   - 类型：免费API
   - 参数：`?url=抖音链接`

2. **XiaoBing API**
   - 地址：`https://api.xingping.vip/api/douyin.php`
   - 类型：免费API
   - 参数：`?url=抖音链接`

3. **QuickSo API**
   - 地址：`https://api.quickso.cn/api/douyin`
   - 类型：免费API
   - 参数：`?url=抖音链接`

4. **开源项目**
   - [Douyin_TikTok_Download_API](https://github.com/Evil0ctal/Douyin_TikTok_Download_API)
   - 可自建服务器
   - 支持多平台

## 测试验证

### 热重载应用
```
在终端按 'r' 键热重载
```

### 测试步骤
1. 粘贴相同的抖音链接
2. 点击"解析视频"
3. 观察新的日志输出

### 预期日志
```
🎬 开始解析视频
检测到抖音链接
策略1: 尝试展开短链接
✓ 短链接展开成功
策略2: 尝试使用多个API解析
⚠️ 主API解析失败
尝试备用API: OGeek
  正在调用 OGeek API...
  API地址: https://api.oick.cn/douyin/api.php
  OGeek 响应状态: 200
  OGeek 响应数据: {code: 1, data: {...}}
  ✓ OGeek 成功获取视频信息
✓ OGeek 解析成功
```

或者如果API都失败：
```
策略3: 尝试HTML爬虫解析
  开始HTML爬虫解析...
  抓取网页: https://www.douyin.com/video/7600582328104095030
  ✓ 网页抓取成功
  ✓ HTML爬虫成功提取视频URL
✓ HTML爬虫解析成功
```

## 优势

### 1. 多层保障
- API失败时有多个备用API
- 所有API失败时有HTML爬虫
- 大大提高成功率

### 2. 适应性强
- 支持多种API响应格式
- 自动识别数据结构
- 容错能力强

### 3. 独立性
- HTML爬虫不依赖第三方API
- 即使所有API失效也能工作
- 更加稳定可靠

## 限制说明

### HTML爬虫的限制
1. **反爬虫机制** - 抖音可能更新反爬虫策略
2. **数据格式变化** - 页面结构可能改变
3. **性能较慢** - 需要下载和解析整个网页

### API限制
1. **免费限制** - 可能有请求次数限制
2. **稳定性** - 免费API可能随时失效
3. **速度** - 响应时间不稳定

## 后续优化建议

1. **添加更多API源**
   - 定期搜索新的可用API
   - 建立API监控机制

2. **优化HTML爬虫**
   - 添加更多数据提取模式
   - 实现智能重试机制
   - 缓存网页内容

3. **自建API服务**
   - 使用[Douyin_TikTok_Download_API](https://github.com/Evil0ctal/Douyin_TikTok_Download_API)
   - 部署到自己的服务器
   - 更加稳定可控

4. **用户反馈机制**
   - 收集失败案例
   - 分析失败原因
   - 持续改进

## 相关资源

### API资源
- [Douyin_TikTok_Download_API](https://github.com/Evil0ctal/Douyin_TikTok_Download_API) - 开源项目
- [TikHub API](https://api.tikhub.io/) - 商业API
- [抖音API解析指南](https://blog.csdn.net/gitblog_01105/article/details/156816725) - 技术文章

### 技术文档
- [HTML解析库](https://pub.dev/packages/html)
- [Dio HTTP客户端](https://pub.dev/packages/dio)
- [正则表达式](https://dart.dev/guides/libraries/library-tour#regular-expressions)

## 修改的文件

1. `lib/services/tiktok_parser_service.dart` - 主要修复
   - 更新备用API列表
   - 添加HTML爬虫方法
   - 增强数据提取逻辑
   - 改进错误处理

2. 新增文档
   - `DOUYIN_FINAL_FIX.md` - 本文档

---

**修复版本**: v1.4
**状态**: ✅ 已完成
**测试状态**: 待用户验证

**下一步**：热重载应用并测试抖音链接解析

---

**Sources:**
- [Douyin_TikTok_Download_API GitHub](https://github.com/Evil0ctal/Douyin_TikTok_Download_API)
- [抖音API数据解析与批量下载实战指南](https://blog.csdn.net/gitblog_01105/article/details/156816725)
- [TikHub-API](https://api.tikhub.io/)
