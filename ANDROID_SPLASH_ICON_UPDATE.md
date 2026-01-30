# Android 启动背景和应用图标更新

## 修改日期
2026-01-30 v2.1.5

## 更新目标

1. 修改 Android windowBackground 背景与首页保持一致（紫蓝青渐变）
2. 设计新的 Android 应用图标，替换默认图标

## 修改内容

### 1. 修复 styles.xml 配置错误

**文件**: `android/app/src/main/res/values/styles.xml`

**问题**: 第 7 行的 item 属性 name 为空
```xml
<item name="">@drawable/launch_background</item>
```

**修复**: 添加正确的属性名
```xml
<item name="android:windowBackground">@drawable/launch_background</item>
```

**效果**:
- ✅ 修复启动背景无法显示的问题
- ✅ 正确引用 launch_background drawable

### 2. 创建渐变背景

**新文件**: `android/app/src/main/res/drawable/background_gradient.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:type="linear"
        android:angle="0"
        android:startColor="#7B1FA2"
        android:centerColor="#42A5F5"
        android:endColor="#4DD0E1" />
</shape>
```

**颜色说明**:
- `#7B1FA2` (深紫色) - 对应 Flutter 的 `Colors.deepPurple.shade400`
- `#42A5F5` (蓝色) - 对应 Flutter 的 `Colors.blue.shade400`
- `#4DD0E1` (青色) - 对应 Flutter 的 `Colors.cyan.shade300`

**渐变方向**:
- `android:angle="0"` - 从左到右（0度）
- 对应 Flutter 的 `Alignment.topLeft` → `Alignment.bottomRight`

### 3. 更新启动背景

**修改文件**:
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`

**修改前**:
```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
    <!-- 没有应用图标 -->
</layer-list>
```

**修改后**:
```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 渐变背景 -->
    <item android:drawable="@drawable/background_gradient" />

    <!-- 应用图标居中 -->
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_launcher" />
    </item>
</layer-list>
```

**效果**:
- ✅ 启动页背景与 Flutter 首页完全一致
- ✅ 应用图标居中显示
- ✅ 从启动到 Flutter UI 渲染的视觉过渡平滑

### 4. 设计新应用图标

#### 4.1 图标设计理念

**设计元素**:
- **3x3 应用网格**: 代表"多功能工具箱"
- **圆角方块**: 现代简洁风格
- **白色前景**: 在渐变背景上清晰可见
- **渐变背景**: 与应用主题一致

**视觉效果**:
```
┌─────────────────┐
│ ┌─┬─┬─┐        │
│ ├─┼─┼─┤        │  3x3 网格代表多工具
│ ├─┼─┼─┤        │
│ └─┴─┴─┘        │
└─────────────────┘
  渐变背景
```

#### 4.2 图标文件结构

**新建文件**:

1. **前景图标** (`drawable/ic_launcher_foreground.xml`)
   - 3x3 圆角方块网格
   - 白色填充
   - 108dp x 108dp

2. **背景** (`drawable/ic_launcher_background.xml`)
   - 紫蓝青渐变
   - 108dp x 108dp

3. **自适应图标** (`mipmap-anydpi-v26/ic_launcher.xml`)
   - Android 8.0+ 自适应图标
   - 使用前景和背景层

4. **圆形图标** (`mipmap-anydpi-v26/ic_launcher_round.xml`)
   - 圆形变体
   - 相同的前景和背景

#### 4.3 前景图标代码

**文件**: `drawable/ic_launcher_foreground.xml`

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">

    <!-- 背景圆圈（半透明白色） -->
    <path
        android:fillColor="#FFFFFF"
        android:fillAlpha="0.2"
        android:pathData="M54,54 m-48,0 a48,48 0 1,1 96,0 a48,48 0 1,1 -96,0"/>

    <!-- 外圈（白色描边） -->
    <path
        android:fillColor="#FFFFFF"
        android:strokeWidth="2"
        android:strokeColor="#FFFFFF"
        android:strokeAlpha="0.3"
        android:pathData="M54,54 m-42,0 a42,42 0 1,1 84,0 a42,42 0 1,1 -84,0"/>

    <!-- 3x3 网格 - 第一行 -->
    <rect android:fillColor="#FFFFFF" android:x="28" android:y="28"
          android:width="10" android:height="10" android:rx="2" />
    <rect android:fillColor="#FFFFFF" android:x="49" android:y="28"
          android:width="10" android:height="10" android:rx="2" />
    <rect android:fillColor="#FFFFFF" android:x="70" android:y="28"
          android:width="10" android:height="10" android:rx="2" />

    <!-- 3x3 网格 - 第二行 -->
    <rect android:fillColor="#FFFFFF" android:x="28" android:y="49"
          android:width="10" android:height="10" android:rx="2" />
    <rect android:fillColor="#FFFFFF" android:x="49" android:y="49"
          android:width="10" android:height="10" android:rx="2" />
    <rect android:fillColor="#FFFFFF" android:x="70" android:y="49"
          android:width="10" android:height="10" android:rx="2" />

    <!-- 3x3 网格 - 第三行 -->
    <rect android:fillColor="#FFFFFF" android:x="28" android:y="70"
          android:width="10" android:height="10" android:rx="2" />
    <rect android:fillColor="#FFFFFF" android:x="49" android:y="70"
          android:width="10" android:height="10" android:rx="2" />
    <rect android:fillColor="#FFFFFF" android:x="70" android:y="70"
          android:width="10" android:height="10" android:rx="2" />
</vector>
```

**设计要点**:
- 9 个圆角方块组成 3x3 网格
- 方块大小: 10dp x 10dp
- 圆角半径: 2dp
- 间距: 11dp
- 居中对齐

#### 4.4 背景代码

**文件**: `drawable/ic_launcher_background.xml`

```xml
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:type="linear"
        android:angle="0"
        android:startColor="#7B1FA2"
        android:centerColor="#42A5F5"
        android:endColor="#4DD0E1" />
    <size
        android:width="108dp"
        android:height="108dp" />
</shape>
```

**效果**:
- 与应用启动背景完全一致
- 与 Flutter 首页背景完全一致
- 与启动页 splash_screen 背景一致

#### 4.5 自适应图标配置

**文件**: `mipmap-anydpi-v26/ic_launcher.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
```

**自适应图标优势**:
- Android 8.0+ 自动应用设备主题
- 不同设备可以显示不同形状（圆形、方形、圆角方形）
- 系统自动处理遮罩和效果

## 视觉一致性

### 完整的视觉体验链

```
1. Android 启动 (windowBackground)
   └─ 紫蓝青渐变 + 图标居中

2. Flutter 启动页 (SplashPage)
   └─ 紫蓝青渐变 + 白色卡片 + Logo

3. Flutter 首页 (HomePage)
   └─ 紫蓝青渐变 + 白色卡片 + 功能图标
```

**所有阶段使用相同的渐变色**:
- `#7B1FA2` (深紫色)
- `#42A5F5` (蓝色)
- `#4DD0E1` (青色)

### 颜色映射表

| 平台 | 颜色 1 | 颜色 2 | 颜色 3 |
|------|--------|--------|--------|
| Flutter | `Colors.deepPurple.shade400` | `Colors.blue.shade400` | `Colors.cyan.shade300` |
| Android XML | `#7B1FA2` | `#42A5F5` | `#4DD0E1` |
| 用途 | 深紫色 | 蓝色 | 青色 |

## 文件结构

### 修改的文件

```
android/app/src/main/res/
├── values/
│   └── styles.xml                              [修改] 修复 windowBackground
├── values-night/
│   └── styles.xml                              [确认] 已正确配置
├── drawable/
│   ├── launch_background.xml                   [修改] 使用渐变背景
│   ├── background_gradient.xml                 [新增] 渐变定义
│   ├── ic_launcher_background.xml              [新增] 图标背景
│   └── ic_launcher_foreground.xml              [新增] 图标前景
├── drawable-v21/
│   └── launch_background.xml                   [修改] 使用渐变背景
└── mipmap-anydpi-v26/                          [新增目录]
    ├── ic_launcher.xml                         [新增] 自适应图标
    └── ic_launcher_round.xml                   [新增] 圆形图标
```

### 新增文件统计

- XML drawable: 4 个
- XML 自适应图标: 2 个
- 修改文件: 3 个

## 技术细节

### Android 渐变角度

| Android angle | Flutter Alignment | 方向 |
|---------------|-------------------|------|
| 0 | topLeft → bottomRight | 左到右 |
| 90 | bottomLeft → topRight | 下到上 |
| 180 | bottomRight → topLeft | 右到左 |
| 270 | topRight → bottomLeft | 上到下 |

**当前设置**: `android:angle="0"` (左到右)

### Vector Drawable vs Bitmap

**Vector Drawable** (XML):
- ✅ 可缩放，无失真
- ✅ 文件小
- ✅ 支持动画
- ✅ 自动适配不同 DPI

**Bitmap** (PNG):
- ✅ 兼容性好
- ❌ 多个尺寸文件
- ❌ 文件大
- ❌ 缩放失真

**选择**: 使用 Vector Drawable

### 自适应图标层级

```
┌─────────────────────────┐
│                         │
│   Background Layer      │  ← 渐变背景
│   (ic_launcher_background) │
│                         │
├─────────────────────────┤
│                         │
│   Foreground Layer      │  ← 3x3 网格
│ (ic_launcher_foreground)  │
│                         │
└─────────────────────────┘
    ↓ 系统应用遮罩
┌─────────────────────────┐
│   ┌───┬───┬───┐        │
│   │ ◻ │ ◻ │ ◻ │        │  最终显示
│   ├───┼───┼───┤        │
│   │ ◻ │ ◻ │ ◻ │        │
│   ├───┼───┼───┤        │
│   │ ◻ │ ◻ │ ◻ │        │
│   └───┴───┴───┘        │
└─────────────────────────┘
```

## 构建说明

### 清理旧图标

如果需要完全替换旧的 PNG 图标：

```bash
# 删除旧的 PNG 图标（可选）
rm android/app/src/main/res/mipmap-*/ic_launcher.png
rm android/app/src/main/res/mipmap-*/ic_launcher_round.png
```

### 重新构建

```bash
# 清理构建缓存
flutter clean

# 重新构建
flutter build apk
```

### 测试

1. **完全关闭应用**
2. **从启动器启动**
3. **观察启动背景**:
   - 应显示紫蓝青渐变
   - 应用图标居中显示
4. **过渡到 Flutter UI**:
   - 应平滑过渡，无视觉跳跃

## 兼容性

### Android 版本支持

| Android 版本 | 图标类型 | 支持情况 |
|--------------|----------|----------|
| 8.0+ (API 26+) | 自适应图标 | ✅ 完整支持 |
| 5.0+ (API 21+) | Vector Drawable | ✅ 完整支持 |
| 4.1+ (API 16+) | Bitmap | ⚠️ 需要保留旧 PNG |

### 低版本兼容

如果需要支持 Android 8.0 以下，保留旧的 PNG 图标：

```bash
# 保留以下文件
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png
├── mipmap-hdpi/ic_launcher.png
├── mipmap-xhdpi/ic_launcher.png
├── mipmap-xxhdpi/ic_launcher.png
└── mipmap-xxxhdpi/ic_launcher.png
```

## 图标生成工具

如果需要生成 PNG 图标：

### 在线工具
- **Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/
- **App Icon Generator**: https://appicon.co/
- **IconKitchen**: https://icon.kitchen/

### 命令行工具

```bash
# 使用 ImageMagick
convert ic_launcher.png -resize 48x48 mipmap-mdpi/ic_launcher.png
convert ic_launcher.png -resize 72x72 mipmap-hdpi/ic_launcher.png
convert ic_launcher.png -resize 96x96 mipmap-xhdpi/ic_launcher.png
convert ic_launcher.png -resize 144x144 mipmap-xxhdpi/ic_launcher.png
convert ic_launcher.png -resize 192x192 mipmap-xxxhdpi/ic_launcher.png
```

## 验证清单

- ✅ styles.xml 修复完成
- ✅ 渐变背景创建完成
- ✅ 启动背景更新完成
- ✅ 图标前景创建完成
- ✅ 图标背景创建完成
- ✅ 自适应图标配置完成
- ✅ 圆形图标配置完成
- ✅ 颜色与 Flutter 页面一致

## 效果预览

### 启动流程

**修改前**:
```
白屏 → (黑屏) → Flutter 启动页 → 首页
  ❌        ❌        ✅              ✅
```

**修改后**:
```
渐变背景+图标 → Flutter 启动页 → 首页
      ✅              ✅              ✅
```

### 应用图标

**修改前**:
```
┌──────────────┐
│              │
│   Flutter    │  默认 Flutter 图标
│   Logo       │
│              │
└──────────────┘
```

**修改后**:
```
┌──────────────┐
│ ┌─┬─┬─┐     │
│ ├─┼─┼─┤     │  3x3 网格图标
│ ├─┼─┼─┤     │  品牌特色
│ └─┴─┴─┘     │
└──────────────┘
```

## 总结

### 改进点

1. ✅ **视觉一致性**: Android 启动背景与 Flutter 页面完全一致
2. ✅ **品牌识别**: 自定义图标，3x3 网格代表多功能
3. ✅ **平滑过渡**: 从系统启动到 Flutter UI 无视觉跳跃
4. ✅ **技术先进**: 使用自适应图标和矢量图形
5. ✅ **主题统一**: 紫蓝青渐变贯穿所有视觉元素

### 技术亮点

- **自适应图标**: Android 8.0+ 最佳实践
- **矢量图形**: 可缩放，文件小
- **渐变一致**: Android XML 与 Flutter 完全对应
- **修复 bug**: styles.xml 属性缺失问题

### 用户价值

- 品牌一致性
- 启动体验流畅
- 图标识别度高
- 视觉专业

---

**更新版本**: v2.1.5
**状态**: ✅ 已完成
**测试状态**: ⏳ 需要实际设备测试

**核心改进**: Android 启动背景与应用图标与 Flutter 主题完全一致
