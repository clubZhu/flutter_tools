# 项目功能清单

## 📱 应用名称
**untitled1** - 多功能工具应用

---

## 🎯 核心功能模块

### 1. 🧮 计算器 (Calculator)
- 基础计算功能
- 支持常用数学运算
- **路由**: `/calculator`

---

### 2. 💬 AI聊天 (AI Chat)
- AI对话界面
- 实时聊天功能
- **路由**: `/chat`

---

### 3. 📋 列表管理 (List)
- 列表数据展示
- 列表项操作
- **路由**: `/list`

---

### 4. 🌐 HTML测试 (HTML Test)
- HTML标签渲染测试
- WebView组件测试
- **路由**: `/html-test`

---

### 5. 🎬 视频下载 (Video Download)
**功能特性**:
- ✅ 支持TikTok/抖音视频链接解析
- ✅ 视频预览功能
- ✅ 视频下载到本地
- ✅ 下载完成后显示存储位置
- ✅ 支持的链接格式:
  - TikTok: `tiktok.com`, `vm.tiktok.com`, `vt.tiktok.com`
  - 抖音: `douyin.com`, `v.douyin.com`, `iesdouyin.com`
- ✅ 使用TikWM API进行视频解析
- ✅ 短链接自动展开（4种策略）
- ✅ 无水印视频下载
- ✅ 高清视频支持
- **路由**: `/video-download`

**解析策略**:
1. 短链接展开（HEAD请求）
2. 短链接展开（GET请求 + 移动UA）
3. 短链接展开（桌面浏览器UA）
4. 短链接展开（抖音App内嵌UA）

---

### 6. 📡 文件传输服务 (WebService)
**功能特性**:
- ✅ 局域网文件传输服务器
- ✅ 启动/停止服务器控制
- ✅ 自动获取局域网IP地址
- ✅ 呼吸动画指示服务器运行状态
- ✅ 文件上传功能
- ✅ 文件下载功能
- ✅ 已上传文件列表展示
- ✅ 上传目录路径显示
- ✅ 自动刷新文件列表（每3秒）
- ✅ 复制存储路径功能
- ✅ Web界面访问（支持拖拽上传）
- **路由**: `/web-service`

**服务器特性**:
- HTTP服务器（默认端口: 8080）
- CORS支持（跨域访问）
- Multipart表单数据解析
- 文件存储位置: `/storage/emulated/0/WebServiceUploads/` (Android)
- 自动权限请求（Android 11+ MANAGE_EXTERNAL_STORAGE）

**API端点**:
- `GET /` - Web控制台界面
- `GET /api/status` - 服务器状态
- `GET /api/files` - 获取已上传文件列表
- `POST /api/upload` - 上传文件
- `GET /api/download?id={id}` - 下载文件

---

## 🔧 技术功能

### 7. 🔐 生物识别认证
- ✅ 应用启动时生物识别验证
- 支持指纹识别
- 支持面部识别（根据设备支持）

### 8. 🌍 国际化 (i18n)
- ✅ 多语言支持
- 支持语言:
  - 🇺🇸 English
  - 🇨🇳 中文
- 使用GetX翻译系统

### 9. 🛣️ 路由管理
- ✅ GetX路由系统
- 统一的路由配置 (`lib/routes/app_navigation.dart`)
- 路由守卫和中间件支持

---

## 🔌 网络层功能

### 10. 🌐 HTTP客户端封装
**Dio网络库**:
- ✅ Dio实例封装
- ✅ 统一错误处理
- ✅ 请求/响应拦截器
- ✅ 日志拦截器
- ✅ 超时配置
- ✅ 自定义API支持

**拦截器功能**:
- 请求头添加
- Token注入
- 错误统一处理
- 请求日志记录

---

## 📦 数据模型

### 11. 📹 视频信息模型 (VideoInfo)
```dart
- id: 视频ID
- title: 视频标题
- description: 视频描述
- coverUrl: 封面URL
- videoUrl: 视频URL
- author: 作者
- platform: 平台 (tiktok/douyin)
- duration: 时长
```

---

## 🎨 UI特性

### 12. 界面功能
- ✅ Material Design 3
- ✅ 深色/浅色主题支持
- ✅ 呼吸动画效果
- ✅ 响应式布局
- ✅ 加载状态指示器
- ✅ 错误提示
- ✅ 成功提示

---

## 🔐 权限管理

### Android权限
```xml
- INTERNET: 网络访问
- WRITE_EXTERNAL_STORAGE: 写入外部存储
- READ_EXTERNAL_STORAGE: 读取外部存储
- MANAGE_EXTERNAL_STORAGE: Android 11+ 管理外部存储
- READ_MEDIA_VIDEO: Android 13+ 读取视频
- READ_MEDIA_IMAGES: Android 13+ 读取图片
- POST_NOTIFICATIONS: 通知权限
```

---

## 🛠️ 开发配置

### 依赖库
```yaml
- flutter_get: ^latest (状态管理、路由)
- dio: ^latest (网络请求)
- permission_handler: ^latest (权限管理)
- path_provider: ^latest (文件路径)
- local_auth: ^latest (生物识别)
- http_server: ^latest (HTTP服务器)
- network_info_plus: ^latest (网络信息)
- open_filex: ^latest (打开文件)
- flutter_markdown: ^latest (Markdown渲染)
- webview_flutter: ^latest (WebView)
```

---

## 📊 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   └── video_info.dart      # 视频信息模型
├── services/                 # 服务层
│   ├── dio_service.dart     # Dio封装
│   ├── dio_interceptor.dart # Dio拦截器
│   ├── tiktok_parser_service.dart  # 视频解析服务
│   └── web_service_server.dart     # 文件传输服务器
├── pages/                    # 页面
│   ├── home_page.dart       # 首页
│   ├── calculator_page.dart # 计算器页
│   ├── chat_page.dart       # AI聊天页
│   ├── list_page.dart       # 列表页
│   ├── html_test_page.dart  # HTML测试页
│   ├── video_download_page.dart   # 视频下载页
│   └── web_service_page.dart      # 文件传输页
├── routes/                   # 路由
│   └── app_navigation.dart  # 路由配置
└── utils/                    # 工具类
```

---

## 🚀 未来可扩展功能

### 潜在新功能
- [ ] 更多视频平台支持（快手、B站等）
- [ ] 批量视频下载
- [ ] 下载历史记录
- [ ] 视频播放器集成
- [ ] 文件传输加密
- [ ] 文件预览功能
- [ ] 云存储集成
- [ ] 更多文件格式支持

---

## 📝 使用说明

### 视频下载流程
1. 打开抖音或TikTok App
2. 选择视频 → 点击分享
3. 复制链接
4. 粘贴到应用的"视频下载"页面
5. 点击解析
6. 预览视频信息
7. 点击下载

### 文件传输流程
1. 确保设备在同一局域网
2. 打开"文件传输"页面
3. 启动服务器
4. 记录显示的服务地址（如: `http://192.168.1.100:8080`）
5. 在其他设备浏览器中访问该地址
6. 上传或下载文件

---

**最后更新**: 2026-01-21
**版本**: 1.0.0
