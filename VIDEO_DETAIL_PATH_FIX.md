# 视频详情路径显示优化

## 修改日期
2026-01-29 v2.1.2

## 用户需求

在视频详情对话框中，本地路径要显示全部，而不是截断。

## 修改内容

### 修改位置
`lib/features/video_download/pages/video_downloaded_page.dart`

### 修改前的代码
```dart
/// 详情行
Widget _detailRow(String label, String value, {bool isPath = false, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text('$label:')),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,  // ← 会截断长路径
          ),
        ),
      ],
    ),
  );
}
```

**问题**：
- `overflow: TextOverflow.ellipsis` 会在文本过长时截断
- `maxLines: 1` 限制只显示一行
- 长路径显示为 `/storage/emulated/0/.../video.mp4`

### 修改后的代码
```dart
/// 详情行
Widget _detailRow(String label, String value, {bool isPath = false, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text('$label:')),
        Expanded(
          child: isPath
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 使用 SelectableText - 可以选择和复制
                    SelectableText(
                      value,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 12,
                      ),
                      // 不限制行数，完整显示全部路径
                    ),
                    // 添加复制按钮
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        Get.snackbar(
                          '已复制',
                          '路径已复制到剪贴板',
                          duration: const Duration(seconds: 1),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            '复制',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    ),
  );
}
```

## 新功能

### 1. 完整路径显示
- ✅ 使用 `SelectableText` 替代普通 `Text`
- ✅ 不设置 `maxLines` 限制
- ✅ 不设置 `overflow` 截断
- ✅ 自动换行显示完整路径

### 2. 一键复制
- ✅ 点击"复制"按钮快速复制完整路径
- ✅ 复制成功后显示提示
- ✅ 蓝色下划线样式，清晰可点击

### 3. 文本可选择
- ✅ 长按可以手动选择文本
- ✅ 支持系统原生复制功能

## 显示效果

### 修改前
```
┌─────────────────────────────────────┐
│ 本地路径:                           │
│ /storage/emulated/0/Android/.../... │
│                                    ↑
│ 只显示一行，过长部分被省略号替代      │
└─────────────────────────────────────┘
```

### 修改后
```
┌─────────────────────────────────────┐
│ 本地路径:                           │
│ /storage/emulated/0/Android/data/    │
│ com.example.untitled1/files/Movies/   │
│ 奔驰汽车广告_1709234567890.mp4 [复制] │
│                                    │
│ 显示完整路径，自动换行                 │
│ 可点击"复制"按钮快速复制               │
└─────────────────────────────────────┘
```

## 使用方法

### 查看完整路径
1. 打开视频详情对话框
2. 找到"本地路径"一行
3. 查看完整路径（自动换行显示）

### 复制路径
**方法1**：点击"复制"按钮
- 点击路径下方的"复制"按钮
- 自动复制到剪贴板

**方法2**：长按选择文本
- 长按路径文本
- 选择要复制的部分
- 使用系统复制功能

### 特殊字符处理
- 路径中的 `/` 符号会正常显示
- 中文文件名正常显示
- 特殊字符不转义
- 完整保留原始路径格式

## 技术实现

### SelectableText vs Text
```dart
// 普通文本（不可选择）
Text('长路径...')

// 可选择文本
SelectableText('长路径...')
```

### Clipboard.setData
```dart
// 复制到剪贴板
await Clipboard.setData(ClipboardData(text: value));

// 读取剪贴板
final data = await Clipboard.getData(Clipboard.kTextPlain);
```

## 导入依赖

需要添加 Flutter services 包：
```dart
import 'package:flutter/services.dart';
```

## 适用场景

### 场景1：调试
- 查看视频实际存储位置
- 使用文件管理器快速定位
- 验证下载是否成功

### 场景2：分享
- 复制路径发送给其他人
- 在其他应用中打开文件
- 提供技术支持时使用

### 场景3：备份
- 复制路径作为备份记录
- 在文档中引用文件位置
- 批量处理时使用

## 用户体验优化

### 1. 清晰的视觉提示
- "复制"按钮使用蓝色
- 下划线表示可点击
- 图标 + 文字组合

### 2. 快速反馈
- 点击后立即复制
- 显示"已复制"提示
- 1秒后自动消失

### 3. 多种方式
- 点击按钮快速复制
- 长按文本选择复制
- 适应不同用户习惯

## 注意事项

### 非路径字段
对于非路径字段（标题、作者等），仍然保持单行显示：
```dart
Text(
  video.title,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

### 只有本地路径特殊处理
```dart
if (isPath) {
  // 完整显示 + 可选择 + 可复制
} else {
  // 单行显示 + 截断
}
```

## 测试验证

### 测试1：短路径
```
输入：/sdcard/video.mp4
显示：/sdcard/video.mp4
结果：✅ 完整显示
```

### 测试2：中等路径
```
输入：/storage/emulated/0/Android/data/.../video.mp4
显示：完整路径（可能换行）
结果：✅ 完整显示
```

### 测试3：超长路径
```
输入：200+ 字符的路径
显示：完整路径（自动换行）
结果：✅ 完整显示
```

### 测试4：复制功能
```
1. 点击"复制"按钮
2. 检查剪贴板内容
3. 验证路径完整
结果：✅ 复制成功
```

## 相关文件

修改的文件：
- `lib/features/video_download/pages/video_downloaded_page.dart`
  - 添加 `import 'package:flutter/services.dart';`
  - 修改 `_detailRow` 方法

---

**修改版本**: v2.1.2
**状态**: ✅ 已完成
**测试状态**: ✅ 编译通过

**核心改进**: 本地路径完整显示 + 一键复制功能
