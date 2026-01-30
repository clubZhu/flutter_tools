# 布局溢出问题修复

## 问题描述
```
A RenderFlex overflowed by 230 pixels on the right.
Row (file://.../video_downloaded_page.dart:468:14)
```

## 问题原因

在 `video_downloaded_page.dart` 的第468行，信息芯片（`_buildInfoChip`）中的 Row 组件没有限制子组件的宽度，导致当文本过长时溢出。

## 修复方案

### 1. 使用 Flexible 包裹文本

**修复前**：
```dart
child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(icon, size: 14),
    SizedBox(width: 4),
    Text('$label: '),  // ← 固定宽度
    Text(             // ← 没有宽度限制
      value,
      overflow: TextOverflow.ellipsis,
    ),
  ],
),
```

**修复后**：
```dart
child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(icon, size: 12),
    SizedBox(width: 3),
    Text('$label:'),
    SizedBox(width: 2),
    Flexible(            // ← 添加 Flexible
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,        // ← 添加最大行数
      ),
    ),
  ],
),
```

### 2. 添加最大宽度限制

```dart
return Container(
  constraints: BoxConstraints(maxWidth: 200),  // ← 限制最大宽度
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  // ...
);
```

### 3. 优化间距和字体

减少内部元素的大小，让内容更紧凑：
- 图标大小：14 → 12
- 间距：4 → 3/2
- 字体：12 → 11
- padding：12 → 10

### 4. 优化 Wrap 间距

```dart
Wrap(
  spacing: 8,   // 从 16 改为 8
  runSpacing: 8,
  children: [...],
)
```

## 修复效果

### 修复前
```
┌────────────────────────────────────┐
│ 时长: 02:35 大小: 15.2MB 位置: /sto...[溢出] │
│                                    ↑ 溢出230像素     │
└────────────────────────────────────┘
```

### 修复后
```
┌────────────────────────────────────┐
│ 时长:02:35 大小:15.2MB              │
│ 位置:app...                         │
└────────────────────────────────────┘
├────────────────────────────────────┤
│ 时长:02:35 大小:15.2MB              │ 自动换行
│ 位置:/storage/.../Movies/...       │
└────────────────────────────────────┘
```

## 技术要点

### Flexible 的作用

```dart
Flexible(
  child: Text('很长的文本内容'),
)
```

- 允许子组件在 Row 中占据剩余空间
- 当空间不足时会压缩
- 配合 `overflow: TextOverflow.ellipsis` 实现文本截断

### BoxConstraints 的作用

```dart
constraints: BoxConstraints(maxWidth: 200)
```

- 限制容器的最大宽度
- 当内容超过200像素时会限制
- 配合 Flexible 实现自适应

### Wrap 的换行

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    _buildInfoChip(...),  // 芯片1
    _buildInfoChip(...),  // 芯片2
    _buildInfoChip(...),  // 芯片3
  ],
)
```

- 当一行放不下时自动换行
- spacing: 芯片之间的水平间距
- runSpacing: 行之间的垂直间距

## 预防措施

### 1. 总是使用 Flexible

```dart
Row(
  children: [
    Icon(),           // 固定大小
    SizedBox(),      // 固定大小
    Expanded(         // 占据剩余空间
      child: Text(),
    ),
  ],
)
```

### 2. 限制文本行数

```dart
Text(
  '很长的文本',
  maxLines: 1,                  // ← 重要！
  overflow: TextOverflow.ellipsis,
)
```

### 3. 使用约束容器

```dart
Container(
  constraints: BoxConstraints(
    maxWidth: 200,
    maxHeight: 100,
  ),
  child: Widget(),
)
```

### 4. 优先使用 Wrap 而非 Row

```dart
// 当子组件数量不固定或可能很长时
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: widgets,
)

// 而不是
Row(
  children: widgets,  // 可能溢出
)
```

## 其他可能溢出的地方

### 操作按钮行

已正确使用 Expanded：
```dart
Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(...),
    ),
    SizedBox(width: 8),
    OutlinedButton(...),
    SizedBox(width: 8),
    OutlinedButton(...),
  ],
)
```

### 详情对话框

已正确使用 Expanded：
```dart
Row(
  children: [
    SizedBox(width: 80, child: Text('$label:')),
    Expanded(              // ← 允许文本扩展
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

## 测试场景

### 场景1：非常长的文件路径
```
修复前：/storage/emulated/0/Android/data/... [溢出]
修复后：/storage/emulated/0/.../Movies/  [截断]
```

### 场景2：多个信息芯片
```
修复前：一行显示3个，最右边的溢出
修复后：自动换行，最多显示2个/行
```

### 场景3：小屏幕设备
```
修复前：小屏幕上可能溢出
修复后：自适应换行 + 文本截断
```

## 调试技巧

### 1. 使用 Flutter DevTools
```
http://127.0.0.1:9100/#/inspector
```

查看组件树，找到溢出的红色区域。

### 2. 添加边框
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.red),
  ),
  child: Widget(),
)
```

### 3. 查看组件大小
```dart
LayoutBuilder(
  builder: (context, constraints) {
    print('可用宽度: ${constraints.maxWidth}');
    return Widget();
  },
)
```

## 常见错误示例

### ❌ 错误1：Row 中没有 Flexible

```dart
Row(
  children: [
    Text('固定文本'),
    Text('可能很长的文本内容导致溢出'),  // 危险！
  ],
)
```

### ❌ 错误2：没有最大宽度限制

```dart
Container(
  padding: EdgeInsets.all(16),
  child: Row(
    children: [
      Text('标签'),
      Text('很长的文本内容'),  // 可能超出屏幕
    ],
  ),
)
```

### ❌ 错误3：没有文本截断

```dart
Text(
  '很长的文本内容',  // 危险！
  // 缺少 overflow 和 maxLines
)
```

## 正确示例

### ✅ 示例1：使用 Flexible

```dart
Row(
  children: [
    Text('标签'),
    Expanded(
      child: Text(
        '很长的文本内容',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ],
)
```

### ✅ 示例2：使用 Wrap

```dart
Wrap(
  spacing: 8,
  children: [
    Chip(label: Text('芯片1')),
    Chip(label: Text('芯片2')),
    Chip(label: Text('芯片3')),
  ],
)
```

### ✅ 示例3：限制宽度

```dart
Container(
  constraints: BoxConstraints(maxWidth: 200),
  child: Text(
    '很长的文本内容',
    overflow: TextOverflow.ellipsis,
  ),
)
```

## 总结

修复要点：
1. ✅ 使用 Flexible 包裹动态文本
2. ✅ 添加 maxWidth 限制容器宽度
3. ✅ 设置 maxLines 和 overflow
4. ✅ 减小字体和间距
5. ✅ 使用 Wrap 替代 Row（多元素时）

---

**修复版本**: v2.1.1
**状态**: ✅ 已修复
**测试**: ✅ 编译通过
