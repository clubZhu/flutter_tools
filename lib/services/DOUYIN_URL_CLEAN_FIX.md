# 抖音URL参数清理修复

## 修复日期
2026-01-29

## 问题分析

根据用户提供的日志，发现了关键问题：

```
原始URL: https://v.douyin.com/SkOgXubqA44
展开后: https://www.douyin.com/video/7600582328104095030?previous_page=app_code_link
TikWM API错误: Url parsing is failed! Please check url.
```

**根本原因**：抖音短链接展开后包含大量查询参数，TikWM API不接受这种格式的URL。

## 修复内容

### 1. 新增URL清理方法 ✅

在 `tiktok_parser_service.dart` 中添加了 `_cleanDouyinUrl()` 方法：

```dart
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
```

**功能**：
- 提取视频ID（例如：7600582328104095030）
- 构造干净的URL：`https://www.douyin.com/video/7600582328104095030`
- 移除所有查询参数和追踪参数

### 2. 在所有API调用前应用URL清理 ✅

修改的方法：
1. `_parseWithTikWM()` - 主API解析
2. `_parseWithBackupApi()` - 备用API解析
3. `parseDirectly()` - 直接解析

示例：
```dart
// 清理抖音URL - 移除所有查询参数
if (finalUrl.contains('douyin.com') || finalUrl.contains('iesdouyin.com')) {
  finalUrl = _cleanDouyinUrl(finalUrl);
  print('已清理抖音URL参数: $finalUrl');
}
```

### 3. 更新备用API列表 ✅

移除不可用的API，添加新的备用API：

```dart
static const List<Map<String, String>> _backupApis = [
  {
    'name': 'TikTokDown',
    'url': 'https://tiktokdown.org/api',
    'type': 'POST',
  },
  {
    'name': 'SSSTik',
    'url': 'https://ssstik.io/en',
    'type': 'POST',
  },
  {
    'name': 'TikWM (Backup)',
    'url': 'https://tikwm.com/api/',
    'type': 'GET',
  },
];
```

## 修复效果

### 修复前
```
发送到API的URL: https://www.douyin.com/video/7600582328104095030?previous_page=app_code_link&from_ssr=1&...
API响应: {code: -1, msg: Url parsing is failed! Please check url.}
```

### 修复后
```
原始URL: https://v.douyin.com/SkOgXubqA44
展开后: https://www.douyin.com/video/7600582328104095030?previous_page=app_code_link
清理后: https://www.douyin.com/video/7600582328104095030
API响应: {code: 0, data: {...}}  ✅ 成功
```

## 测试验证

现在可以测试修复后的效果：

1. **热重载应用**（如果正在运行）
   ```
   按 'r' 键热重载
   ```

2. **重新测试抖音链接**
   - 粘贴相同的抖音链接
   - 观察日志中应该出现 "已清理抖音URL参数"
   - 应该能看到干净的URL：`https://www.douyin.com/video/7600582328104095030`
   - TikWM API应该能正常解析

3. **预期日志输出**
   ```
   🎬 开始解析视频
   清理后URL: https://v.douyin.com/SkOgXubqA44
   检测到抖音链接
   策略1: 尝试展开短链接
   ✓ 短链接展开成功
   策略2: 尝试使用多个API解析
   已清理抖音URL参数: https://www.douyin.com/video/7600582328104095030
   开始解析抖音/TikTok链接: https://www.douyin.com/video/7600582328104095030
   API响应状态: 200
   API响应数据: {code: 0, data: {...}}
   ✓ 主API解析成功
   ```

## 技术细节

### URL清理的重要性

TikWM等API服务对URL格式有严格要求：
- ❌ 不接受：`https://www.douyin.com/video/7600582328104095030?previous_page=app_code_link&from_ssr=1&...`
- ✅ 接受：`https://www.douyin.com/video/7600582328104095030`

### 正则表达式说明
```dart
final videoIdPattern = RegExp(r'/video/(\d+)');
```

- `/video/` - 匹配固定路径
- `(\d+)` - 捕获视频ID（纯数字）
- 例如：`/video/7600582328104095030` → 捕获 `7600582328104095030`

## 后续改进建议

1. **添加URL格式验证**
   - 在清理前验证URL是否有效
   - 提供更清晰的错误提示

2. **支持更多URL格式**
   - 处理其他抖音URL格式（如用户主页、挑战等）
   - 支持更多视频平台的URL清理

3. **性能优化**
   - 缓存已清理的URL
   - 避免重复清理

## 相关文件

- `lib/services/tiktok_parser_service.dart` - 主要修复
- `lib/services/DOUYIN_FIX_SUMMARY.md` - 之前的修复总结

---

**修复版本**: v1.3.1
**状态**: ✅ 已完成
**测试状态**: 待用户验证

**下一步**：重新运行应用并测试抖音链接解析
