# 视频下载问题排查指南

## 已修复的问题

### 1. Android权限问题 ✅
**问题**: AndroidManifest.xml缺少必要的权限声明

**已添加的权限**:
```xml
<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- 存储权限 -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<!-- Android 13+ 照片/视频权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- 通知权限 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2. 下载服务改进 ✅
**优化内容**:
- 增加URL验证
- 改进权限请求逻辑（区分Android版本）
- 修复保存目录问题
- 添加下载完成验证
- 增加超时配置（10分钟）
- 改进文件名处理

---

## 视频下载位置

### Android
```
/storage/emulated/0/Android/data/com.example.untitled1/files/Movies/
```

或者在应用中：
```
设置 > 存储 > Android/data/com.example.untitled1/files/Movies/
```

### iOS
```
App Documents/Documents/Videos/
```

---

## 如何测试视频下载

### 方法1: 使用测试视频

在video_download_page.dart中添加测试按钮：

```dart
// 在_buildUrlInputSection后添加
ElevatedButton(
  onPressed: () async {
    final testVideo = VideoInfo(
      id: 'test',
      title: '测试视频',
      description: '这是一个公开的测试视频',
      coverUrl: 'https://picsum.photos/400/300',
      videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10MB_5mb.mp4',
      author: 'Test',
      platform: 'test',
    );

    setState(() {
      _videoInfo = testVideo;
      _errorMessage = null;
    });

    _scrollToPreview();
    _initVideoPlayer(testVideo.videoUrl);
  },
  child: const Text('使用测试视频'),
),
```

### 方法2: 测试真实视频URL

#### YouTube测试链接
```
https://www.youtube.com/watch?v=aqz-KE-bpKQ
```

#### TikTok测试链接
```
https://www.tiktok.com/@scout2015/video/6718335390845095173
```

#### 抖音测试链接
```
https://www.douyin.com/video/7123456789012345678
```

---

## 常见问题排查

### Q1: 点击下载后没有反应
**原因**:
- 权限被拒绝
- 视频URL为空

**解决方法**:
1. 检查应用权限设置
2. 查看控制台日志: `flutter run -v`
3. 确认视频解析成功

### Q2: 下载进度卡住不动
**原因**:
- 网络连接问题
- 视频服务器响应慢
- URL无效或已过期

**解决方法**:
1. 切换到更稳定的网络
2. 尝试重新解析视频
3. 刷新视频链接

### Q3: 下载完成但找不到文件
**原因**:
- 保存路径不正确
- 文件管理器没有刷新

**解决方法**:
1. 使用文件管理器查看：
   - 路径: `Android/data/com.example.untitled1/files/Movies/`
2. 或者在相册应用中查看
3. 重启设备后刷新媒体库

### Q4: 显示"下载失败"
**可能原因**:
1. **权限问题**
   - 检查设置 > 应用 > 权限 > 存储
   - 允许访问存储权限

2. **存储空间不足**
   - 检查设备可用空间
   - 清理不必要的文件

3. **网络问题**
   - 检查网络连接
   - 尝试切换WiFi/移动网络

4. **URL失效**
   - 视频链接已过期
   - 需要重新解析获取新链接

---

## 调试步骤

### 1. 启用详细日志
运行应用时使用verbose模式：
```bash
flutter run -v
```

### 2. 检查日志输出
查找关键信息：
```
开始下载: [URL]
保存到: [路径]
下载完成，文件大小: XX MB
```

### 3. 验证解析结果
确认解析成功：
```
解析成功:
- 标题: xxx
- 视频: xxx
- 作者: xxx
```

### 4. 测试权限
```dart
// 在代码中测试权限
final service = VideoDownloadService();
final hasPermission = await service.requestStoragePermission();
print('权限状态: $hasPermission');
```

---

## 改进建议

### 已实现的改进 ✅
1. 添加完整的Android权限声明
2. 改进权限请求逻辑
3. 修复保存目录问题
4. 添加下载验证
5. 增加超时配置
6. 改进错误提示

### 可选改进
1. 添加下载队列
2. 支持后台下载
3. 添加下载速度显示
4. 支持断点续传
5. 保存到系统相册（需要额外配置）

---

## 测试清单

下载功能正常工作的标志：
- [ ] 可以正常请求权限
- [ ] 权限授予后可以开始下载
- [ ] 下载进度正常显示
- [ ] 下载完成后显示成功提示
- [ ] 可以在文件管理器中找到下载的视频
- [ ] 视频可以正常播放

---

## 技术支持

如果问题依然存在：

1. **查看完整日志**
   ```bash
   flutter run -v 2>&1 | tee debug.log
   ```

2. **检查设备信息**
   - Android版本
   - 可用存储空间
   - 网络连接状态

3. **重装应用**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **使用真机测试**
   - 模拟器可能有存储限制
   - 真机测试更准确

---

## 更新日志

### v1.1 (2024-01-20)
- ✅ 修复Android权限问题
- ✅ 改进下载服务
- ✅ 添加下载验证
- ✅ 优化错误提示
- ✅ 增加调试日志

### v1.0 (2024-01-20)
- ✅ 集成YouTube解析
- ✅ 集成TikTok/抖音解析
- ✅ 实现视频下载功能
- ✅ 实现视频预览
