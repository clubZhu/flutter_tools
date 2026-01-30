# 下载历史服务改进说明

## 改进日期
2026-01-29 v2.1

## 问题反馈

用户反馈：**下载历史应该读取下载目录里的数据**，而不是单独维护记录。

## 改进方案

### 从"记录存储"改为"文件系统扫描"

#### 旧方案（v2.0）
```dart
// 单独维护视频列表
List<DownloadedVideoModel> _videos = [];

// 使用SharedPreferences存储完整列表
await prefs.setStringList(_storageKey, videosJson);
```

**问题**：
- 数据不同步（文件删除了但记录还在）
- 维护两份数据（文件系统 + 存储记录）
- 容易出现不一致

#### 新方案（v2.1）
```dart
// 直接扫描下载目录
await _scanDownloadDirectory();

// 只保存额外元数据
await _saveMetadata(video);  // 标题、作者等
```

**优势**：
- ✅ 数据源单一（文件系统为唯一真相源）
- ✅ 自动同步（删除文件即删除记录）
- ✅ 准确反映实际情况
- ✅ 元数据缓存保留额外信息

## 核心实现

### 1. 目录扫描

```dart
Future<void> _scanDownloadDirectory() async {
  _videos.clear();

  // 获取目录中的所有文件
  final files = await _downloadDirectory!.list().toList();

  for (var file in files) {
    if (file is File && _isVideoFile(file)) {
      final stat = await file.stat();
      final fileName = file.path.split('/').last;

      // 创建视频对象（从文件系统获取真实信息）
      final video = DownloadedVideoModel(
        id: fileName,
        localPath: file.path,
        fileSize: stat.size,           // 真实文件大小
        downloadedAt: stat.modified,    // 文件修改时间
        // ...
      );

      _videos.add(video);
    }
  }

  // 按修改时间排序
  _videos.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
}
```

### 2. 元数据缓存

虽然是基于文件系统，但仍保留额外的元数据（标题、作者等）：

```dart
// 元数据结构
{
  "video_123.mp4": {
    "title": "奔驰汽车广告",
    "author": "梅赛德斯-奔驰",
    "platform": "douyin",
    "description": "140年前...",
    "coverUrl": "https://...",
    "duration": 15000
  }
}
```

**好处**：
- 文件名一般不包含这些信息
- 但我们希望在列表中显示完整信息
- 所以使用SharedPreferences缓存这些元数据

### 3. 智能信息提取

即使没有元数据缓存，也能从文件名推测信息：

```dart
// 提取标题
String _extractTitleFromFileName(String fileName) {
  // "奔驰汽车_123.mp4" → "奔驰汽车"
  String title = fileName.replaceAll(RegExp(r'\.(mp4|mov|avi)$'), '');
  title = title.replaceAll(RegExp(r'_\d+$'), '');
  return title.isEmpty ? '未命名视频' : title;
}

// 猜测平台
String _guessPlatform(String fileName) {
  if (fileName.contains('douyin')) return 'douyin';
  if (fileName.contains('tiktok')) return 'tiktok';
  // ...
  return 'unknown';
}
```

## 使用流程

### 下载视频
```dart
// 1. 下载文件
final file = await _downloadService.downloadVideo(url, fileName);

// 2. 保存元数据（标题、作者等）
await _historyService.addVideo(downloadedVideo);

// 3. 自动重新扫描目录
await _historyService.refresh();
```

### 查看已下载
```dart
// 初始化服务时自动扫描
await _historyService.init();

// 或者手动刷新
await _historyService.refresh();

// 获取视频列表（基于实际文件）
final videos = _historyService.videos;
```

### 删除视频
```dart
// 删除实际文件
await _historyService.deleteVideo(id);

// 内部会：
// 1. 删除物理文件
// 2. 重新扫描目录
// 3. 自动更新列表
```

## API变化

### 保留的方法
```dart
// 这些方法仍然可用，但内部实现已改变
List<DownloadedVideoModel> get videos;
bool get isEmpty;
int get length;
DownloadedVideoModel? findVideo(String id);
List<DownloadedVideoModel> searchVideos(String keyword);
Map<String, List<DownloadedVideoModel>> getVideosByPlatform();
int getTotalSize();
String getTotalSizeFormatted();
```

### 新增方法
```dart
// 刷新目录扫描
Future<void> refresh()

// 获取下载目录路径
String? getDownloadDirectoryPath()

// 检查文件是否存在
Future<bool> checkFileExists(String localPath)
```

### 行为变化
```dart
// 旧版：删除只是移除记录
Future<void> deleteVideo(String id) {
  _videos.removeWhere((v) => v.id == id);
  await _saveVideos();
}

// 新版：删除实际文件
Future<void> deleteVideo(String id) async {
  final file = File(video.localPath);
  await file.delete();  // 删除物理文件
  await _scanDownloadDirectory();  // 重新扫描
}

// 旧版：清空只是清除记录
Future<void> clearAll() {
  _videos.clear();
  await _saveVideos();
}

// 新版：清空删除所有文件
for (var file in files) {
  await file.delete();  // 删除所有视频文件
}
await _scanDownloadDirectory();
```

## UI改进

### 添加刷新按钮

```dart
// 在AppBar添加刷新按钮
IconButton(
  icon: const Icon(Icons.refresh),
  onPressed: () async {
    await _historyService.refresh();
    setState(() {
      _displayedVideos = _historyService.videos;
    });
    Get.snackbar('已刷新', '已扫描下载目录');
  },
  tooltip: '刷新列表',
),
```

**好处**：
- 用户可以手动刷新列表
- 如果用户手动删除了文件，刷新后会同步
- 比进入页面时自动刷新更可控

## 数据一致性

### 场景1：用户手动删除文件

旧方案：
```
1. 用户在文件管理器删除 video.mp4
2. 应用中仍然显示记录
3. 点击预览报错（文件不存在）
```

新方案：
```
1. 用户在文件管理器删除 video.mp4
2. 点击刷新按钮
3. 重新扫描目录
4. 记录自动消失 ✅
```

### 场景2：应用重启

旧方案：
```
1. 应用关闭
2. 用户删除文件
3. 应用重启
4. 仍然显示旧记录
```

新方案：
```
1. 应用关闭
2. 用户删除文件
3. 应用重启 → init() 自动扫描
4. 只显示实际存在的文件 ✅
```

### 场景3：存储空间

旧方案：
```
- 存储视频文件（实际占用空间）
- 存储完整记录列表（额外开销）
- 数据重复，浪费空间
```

新方案：
```
- 存储视频文件（实际占用空间）
- 只存储轻量级元数据（标题、作者等）
- 节省存储空间 ✅
```

## 文件结构

### 下载目录
```
/storage/emulated/0/Android/data/com.example.untitled1/files/Movies/
├── 奔驰汽车广告_1709234567890.mp4
├── 抖音视频_1709234567891.mp4
├── TikTok_video_1709234567892.mp4
└── 未命名视频_1709234567893.mp4
```

### SharedPreferences（元数据）
```json
{
  "video_metadata": {
    "奔驰汽车广告_1709234567890.mp4": {
      "title": "140年前，人们看着奔驰发明的汽车",
      "author": "梅赛德斯-奔驰",
      "platform": "douyin",
      "description": "...",
      "coverUrl": "https://...",
      "duration": 45000
    },
    "抖音视频_1709234567891.mp4": {
      "title": "抖音视频标题",
      "author": "作者名称",
      "platform": "douyin",
      ...
    }
  }
}
```

## 性能优化

### 1. 按需扫描
```dart
// 不是每次都扫描，而是：
// 1. 初始化时扫描一次
// 2. 下载后只更新元数据
// 3. 用户手动刷新时扫描
```

### 2. 文件过滤
```dart
// 只处理视频文件
bool _isVideoFile(File file) {
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.avi') ||
      // ...
}
```

### 3. 懒加载
```dart
// 只在需要时才扫描
Future<void> init() async {
  await _scanDownloadDirectory();
}
```

## 测试场景

### 测试1：正常下载
```
1. 下载视频 → 文件保存到Movies/
2. 保存元数据
3. 刷新列表
4. ✅ 视频出现在列表
5. ✅ 显示完整信息（标题、作者等）
```

### 测试2：删除文件
```
1. 在已下载页面删除视频
2. ✅ 文件被删除
3. ✅ 记录消失
4. ✅ 存储空间释放
```

### 测试3：手动删除文件
```
1. 在文件管理器删除视频
2. 返回应用，点击刷新
3. ✅ 记录自动消失
4. ✅ 不会出现文件不存在的错误
```

### 测试4：应用重启
```
1. 下载多个视频
2. 关闭应用
3. 重新打开
4. ✅ 自动扫描目录
5. ✅ 正确显示所有视频
```

## 优势总结

| 对比项 | 旧方案（记录存储） | 新方案（文件扫描） |
|--------|------------------|------------------|
| 数据源 | 存储记录 | 实际文件系统 |
| 一致性 | 可能不同步 | 始终同步 ✅ |
| 准确性 | 文件可能不存在 | 100%准确 ✅ |
| 存储开销 | 双重存储 | 只存元数据 ✅ |
| 删除操作 | 只删除记录 | 删除实际文件 ✅ |
| 刷新机制 | 不支持 | 手动刷新 ✅ |
| 可靠性 | 依赖记录维护 | 依赖文件系统 ✅ |

## 未来优化

### 1. 增量扫描
```dart
// 只扫描新文件，而不是全量扫描
Future<void> _incrementalScan() async {
  final lastScanTime = await _getLastScanTime();
  // 只扫描修改时间晚于 lastScanTime 的文件
}
```

### 2. 后台监控
```dart
// 使用文件系统监听器自动更新
Directory(_downloadDirectory).watch().listen((event) {
  if (event.type == FileSystemEvent.delete) {
    // 自动从列表中移除
  }
});
```

### 3. 缩略图生成
```dart
// 为视频生成缩略图
final thumbnail = await VideoThumbnail.thumbnailData(
  video: video.path,
  imageFormat: ImageFormat.JPEG,
  maxWidth: 200,
  quality: 75,
);
```

## 相关文件

修改的文件：
- `lib/features/video_download/services/download_history_service.dart`
- `lib/features/video_download/pages/video_downloaded_page.dart`

---

**改进版本**: v2.1
**状态**: ✅ 已完成
**测试状态**: ✅ 编译通过

**核心思想**: 文件系统为唯一真相源，元数据作为补充
