# Android Gradient Angle 与 Flutter Alignment 对应关系

## Flutter LinearGradient 配置

### 首页渐变配置
```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Colors.deepPurple.shade400,  // #7B1FA2
    Colors.blue.shade400,         // #42A5F5
    Colors.cyan.shade300,         // #4DD0E1
  ],
)
```

**方向**: 从左上角到右下角 (↘)

## Android Gradient Angle 系统

### 角度说明

Android 的 `android:angle` 属性定义渐变方向，单位是度：

```
    0° (→)
      |
90° (↑) |
      |
      |
270°/-90° (↓)

    180° (←)
```

### 角度对应表

| Android angle | 方向 | 对应 Flutter |
|---------------|------|--------------|
| 0 | → (左到右) | `Alignment.centerLeft` → `Alignment.centerRight` |
| 45 | ↗ (左下到右上) | `Alignment.bottomLeft` → `Alignment.topRight` |
| 90 | ↑ (下到上) | `Alignment.bottomCenter` → `Alignment.topCenter` |
| **135** | **↘ (左上到右下)** | **`Alignment.topLeft` → `Alignment.bottomRight`** |
| 180 | ← (右到左) | `Alignment.centerRight` → `Alignment.centerLeft` |
| 225 | ↙ (右上到左下) | `Alignment.topRight` → `Alignment.bottomLeft` |
| **270 / -90** | **↓ (上到下)** | **`Alignment.topCenter` → `Alignment.bottomCenter`** |
| 315 / -45 | ↖ (左上到右下？) | `Alignment.topRight` → `Alignment.bottomLeft`？ |

## 当前配置

### Android (background_gradient.xml)
```xml
<gradient
    android:type="linear"
    android:angle="-45"
    android:startColor="#7B1FA2"
    android:centerColor="#42A5F5"
    android:endColor="#4DD0E1" />
```

**当前角度**: -45° (即 315°)
**方向**: 可能是从右上到左下或变体

### Flutter (home_page.dart)
```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  ...
)
```

**方向**: 从左上到右下 (↘)

## 建议配置

### 选项 1: 使用 135° (标准左上到右下)

```xml
<gradient
    android:type="linear"
    android:angle="135"
    android:startColor="#7B1FA2"
    android:centerColor="#42A5F5"
    android:endColor="#4DD0E1" />
```

**效果**: 完全匹配 Flutter 的 `topLeft` → `bottomRight`

### 选项 2: 使用 -45° (用户当前配置)

```xml
<gradient
    android:type="linear"
    android:angle="-45"
    android:startColor="#7B1FA2"
    android:centerColor="#42A5F5"
    android:endColor="#4DD0E1" />
```

**效果**: -45° = 315°，可能是从右上到左下或镜像效果

### 选项 3: 测试其他角度

如果需要微调，可以尝试：
- **125°**: 稍微偏上的对角线
- **135°**: 标准 45° 对角线
- **145°**: 稍微偏下的对角线
- **-45°**: 可能是镜像方向

## 颜色值确认

### Flutter Colors 转 Android Hex

| Flutter Color | Hex Code | Android |
|---------------|----------|---------|
| `Colors.deepPurple.shade400` | #7B1FA2 | `#7B1FA2` ✅ |
| `Colors.blue.shade400` | #42A5F5 | `#42A5F5` ✅ |
| `Colors.cyan.shade300` | #4DD0E1 | `#4DD0E1` ✅ |

**颜色完全匹配** ✅

## 视觉对比

### 标准左上到右下 (135°)

```
┌─────────────────────┐
│ #7B1FA2            │ 深紫色 (左上)
│      ↘             │
│   #42A5F5          │ 蓝色 (中间)
│        ↘           │
│          #4DD0E1   │ 青色 (右下)
└─────────────────────┘
```

### 如果使用 -45°

-45° = 315°，可能是：

```
┌─────────────────────┐
│           #4DD0E1  │ 青色 (右上?)
│      ↙             │
│   #42A5F5          │ 蓝色
│        ↙           │
│ #7B1FA2            │ 深紫色 (左下?)
└─────────────────────┘
```

**或镜像版本**，取决于 Android 实现。

## 调试建议

### 1. 创建测试页面

在 Flutter 中创建一个测试页面，只显示渐变背景：

```dart
class GradientTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7B1FA2), // deepPurple.shade400
              Color(0xFF42A5F5), // blue.shade400
              Color(0xFF4DD0E1), // cyan.shade300
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Flutter Gradient\ntopLeft → bottomRight',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    );
  }
}
```

### 2. 截图对比

1. 显示 Android 启动背景并截图
2. 显示 Flutter 测试页面并截图
3. 对比两张截图的渐变方向

### 3. 角度调整

如果 135° 不匹配，尝试：

```xml
<!-- 稍微调整角度 -->
android:angle="125"  <!-- 更偏向水平 -->
android:angle="135"  <!-- 标准 45 度 -->
android:angle="145"  <!-- 更偏向垂直 -->
```

## Android Gradient Angle 详细说明

### 计算方法

Android angle 是顺时针方向，从 0° 开始（3点钟方向）：

```
        90° (↑)
          |
          |
270°/-90° ↓ ---- 0° (→)
          |
          |
        180° (←)
```

### Flutter Alignment 映射

| Flutter Alignment | 对应 Android angle | 说明 |
|-------------------|-------------------|------|
| `topLeft` → `topRight` | 0 | 水平向右 |
| `topLeft` → `bottomRight` | **135** | **主对角线** |
| `bottomLeft` → `topRight` | 45 | 副对角线 |
| `topLeft` → `bottomLeft` | 270/-90 | 垂直向下 |
| `topCenter` → `bottomCenter` | 270/-90 | 垂直向下 |

### 为什么是 135°？

从左上到右下是 45° 角（从水平线逆时针），但 Android angle 是顺时针：

```
    0° (→)
   /
  / 45° (从左到上)
 /
•--------→ 0°
 \
  \ 135° (从左上到右下)
   \
    ↓
```

或者更简单的理解：
- 左上角是西北方向
- 右下角是东南方向
- 西北到东南 = 135° (西南方向 + 45°)

## 实际效果

### 当前使用 -45° 的可能效果

-45° = 315°，这在圆周上接近顶部（0°）：

```
       0°
      ↗
     /   -45° (315°)
    /
   •--------→
```

这可能产生：
1. 从右上到左下的渐变
2. 镜像的左上到右下渐变
3. 其他变体效果

## 推荐方案

### 方案 A: 使用标准 135°

```xml
<gradient
    android:type="linear"
    android:angle="135"
    ... />
```

**优点**:
- 理论上完全匹配 Flutter
- 标准对角线渐变
- 文档明确

**缺点**:
- 可能因设备实现略有差异

### 方案 B: 微调角度

```xml
<gradient
    android:type="linear"
    android:angle="140"
    ... />
```

**优点**:
- 可以精确匹配
- 补偿系统差异

**缺点**:
- 需要反复测试
- 因设备而异

### 方案 C: 保持当前 -45°

```xml
<gradient
    android:type="linear"
    android:angle="-45"
    ... />
```

**如果效果已匹配，保持不变。**

## 验证方法

### 视觉检查清单

- [ ] Android 启动背景渐变方向
- [ ] Flutter 首页渐变方向
- [ ] 两者是否一致
- [ ] 颜色过渡是否平滑
- [ ] 是否有明显的渐变断层

### 截图对比

1. **Android 启动背景截图**
   - 完全关闭应用
   - 重新启动
   - 在渐变背景显示时截图

2. **Flutter 首页截图**
   - 进入应用首页
   - 截取相同区域

3. **对比分析**
   - 叠加两张截图
   - 检查渐变方向
   - 检查颜色过渡

## 技术细节

### Android Gradient Stops

如果需要更精确控制渐变位置：

```xml
<gradient
    android:type="linear"
    android:angle="135"
    android:startColor="#7B1FA2"
    android:centerColor="#42A5F5"
    android:centerX="0.5"
    android:centerY="0.5"
    android:endColor="#4DD0E1" />
```

### Flutter Color Stops 对应

```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF7B1FA2),  // 0.0
    Color(0xFF42A5F5),  // 0.5 (隐含中间)
    Color(0xFF4DD0E1),  // 1.0
  ],
  stops: [0.0, 0.5, 1.0],  // 可选
)
```

## 总结

### Flutter 配置
- **方向**: `Alignment.topLeft` → `Alignment.bottomRight`
- **角度**: 45° 对角线 (从左上到右下)

### Android 理论配置
- **角度**: 135°
- **说明**: Android angle 是顺时针，135° = 左上到右下

### 当前用户配置
- **角度**: -45° (315°)
- **说明**: 可能已通过实际测试调整

### 建议
如果 -45° 在你的设备上看起来与 Flutter 首页一致，那就保持这个配置。不同设备可能有细微差异，实际效果为准。

---

**文档版本**: v1.0
**最后更新**: 2026-01-30
**状态**: 参考文档
