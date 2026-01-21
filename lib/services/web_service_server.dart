import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// WebService服务器
class WebServiceServer {
  WebServiceServer._();

  static final WebServiceServer _instance = WebServiceServer._();

  factory WebServiceServer() => _instance;

  HttpServer? _server;
  bool _isRunning = false;
  String? _localIp;
  int _port = 8080;
  final List<Map<String, dynamic>> _uploadedFiles = [];

  bool get isRunning => _isRunning;
  String? get serverUrl => _localIp != null ? 'http://$_localIp:$_port' : null;
  List<Map<String, dynamic>> get uploadedFiles => _uploadedFiles;

  Future<void> init() async {
    await _getLocalIp();
  }

  Future<void> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      if (wifiIP != null && wifiIP != '127.0.0.1') {
        _localIp = wifiIP;
        print('✓ 局域网IP: $_localIp');
        return;
      }

      final interfaces = await NetworkInterface.list(includeLoopback: false);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type.name == 'IPv4' && !addr.address.startsWith('127.')) {
            _localIp = addr.address;
            print('✓ 局域网IP: $_localIp');
            return;
          }
        }
      }

      _localIp = 'localhost';
      print('⚠ 使用localhost');
    } catch (e) {
      print('获取IP失败: $e');
      _localIp = 'localhost';
    }
  }

  Future<bool> startServer({int port = 8080}) async {
    if (_isRunning) return false;

    // 请求存储权限
    if (Platform.isAndroid) {
      final status = await _requestStoragePermission();
      if (!status) {
        print('❌ 存储权限被拒绝，无法保存文件');
        // 仍然启动服务器，但文件可能无法保存
      }
    }

    _port = port;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('✅ 服务器启动成功，监听端口: $port');
      print('📍 访问地址: http://$_localIp:$port');

      _server!.listen((request) {
        print('📨 [${request.method}] ${request.uri.path}');
        _handleRequest(request);
      });

      _isRunning = true;
      return true;
    } catch (e) {
      print('❌ 启动失败: $e');
      return false;
    }
  }

  /// 请求存储权限
  Future<bool> _requestStoragePermission() async {
    try {
      print('🔐 请求存储权限...');

      // Android 11+ (API 30+)
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 30) {
          // Android 11+ 需要管理外部存储权限
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            print('❌ MANAGE_EXTERNAL_STORAGE 权限被拒绝');
            // 尝试传统权限
            final writeStatus = await Permission.storage.request();
            return writeStatus.isGranted;
          }
          print('✓ MANAGE_EXTERNAL_STORAGE 权限已授予');
          return true;
        } else {
          // Android 10 及以下使用传统权限
          final status = await Permission.storage.request();
          if (status.isGranted) {
            print('✓ 存储权限已授予');
            return true;
          }
          print('❌ 存储权限被拒绝');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('⚠️ 权限请求异常: $e');
      return false;
    }
  }

  /// 获取Android版本号
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    // 如果无法获取，返回一个合理的默认值
    try {
      // 这里可以简化处理，实际项目中可以使用 device_info_plus
      return 30; // 假设是Android 11+
    } catch (e) {
      return 30;
    }
  }

  Future<bool> stopServer() async {
    if (!_isRunning) return false;

    try {
      await _server!.close();
      _server = null;
      _isRunning = false;
      _uploadedFiles.clear();
      print('✅ 服务器已停止');
      return true;
    } catch (e) {
      print('❌ 停止失败: $e');
      return false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;

    // CORS
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      response.statusCode = 200;
      await response.close();
      return;
    }

    try {
      final path = request.uri.path;

      switch (path) {
        case '/':
        case '/index.html':
          await _serveHomePage(response);
          break;
        case '/api/status':
          await _serveStatus(response);
          break;
        case '/api/files':
          await _serveFiles(response);
          break;
        case '/api/upload':
          await _handleUpload(request, response);
          break;
        case '/api/download':
          await _handleDownload(request, response);
          break;
        default:
          response.statusCode = 404;
          response.write('404 Not Found');
          await response.close();
      }
    } catch (e) {
      print('❌ 处理请求错误: $e');
      response.statusCode = 500;
      response.write('Error: $e');
      await response.close();
    }
  }

  Future<void> _serveHomePage(HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.write(_generateHtml());
    await response.close();
  }

  String _generateHtml() {
    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>文件传输服务</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; margin-bottom: 20px; }
        .upload-area {
            border: 2px dashed #007bff;
            border-radius: 8px;
            padding: 40px;
            text-align: center;
            margin: 20px 0;
            background: #f8f9fa;
        }
        .upload-area.dragover {
            background: #e9ecef;
            border-color: #0056b3;
        }
        button {
            padding: 10px 20px;
            background: #007bff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover { background: #0056b3; }
        button:disabled { opacity: 0.5; cursor: not-allowed; }
        #fileList {
            margin-top: 20px;
        }
        .file-item {
            padding: 10px;
            margin: 5px 0;
            background: #f8f9fa;
            border-radius: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        #log {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 4px;
            font-family: monospace;
            font-size: 12px;
            max-height: 200px;
            overflow-y: auto;
            margin-top: 20px;
        }
        .log-entry { margin: 2px 0; }
        .log-success { color: green; }
        .log-error { color: red; }
        .log-info { color: blue; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📁 文件传输服务</h1>

        <div class="upload-area" id="dropZone">
            <p>点击下方按钮选择文件，或拖拽文件到此处</p>
            <input type="file" id="fileInput" style="display: none;">
            <button onclick="document.getElementById('fileInput').click()">选择文件</button>
        </div>

        <div id="fileList"></div>

        <h3>调试日志</h3>
        <div id="log"></div>
    </div>

    <script>
        function log(msg, type = 'info') {
            const logDiv = document.getElementById('log');
            const entry = document.createElement('div');
            entry.className = 'log-entry log-' + type;
            entry.textContent = '[' + new Date().toLocaleTimeString() + '] ' + msg;
            logDiv.appendChild(entry);
            console.log(msg);
        }

        // 自动加载文件列表
        window.onload = function() {
            log('页面加载完成');
            loadFiles();
        };

        // 文件选择
        document.getElementById('fileInput').addEventListener('change', function(e) {
            if (e.target.files.length > 0) {
                uploadFile(e.target.files[0]);
            }
        });

        // 拖拽上传
        const dropZone = document.getElementById('dropZone');

        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });

        dropZone.addEventListener('dragleave', () => {
            dropZone.classList.remove('dragover');
        });

        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            if (e.dataTransfer.files.length > 0) {
                uploadFile(e.dataTransfer.files[0]);
            }
        });

        // 上传文件
        function uploadFile(file) {
            log('开始上传: ' + file.name + ' (' + file.size + ' bytes)', 'info');

            const formData = new FormData();
            formData.append('file', file);

            const xhr = new XMLHttpRequest();

            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable) {
                    const percent = Math.round((e.loaded / e.total) * 100);
                    log('上传进度: ' + percent + '%', 'info');
                }
            });

            xhr.addEventListener('load', () => {
                log('HTTP状态: ' + xhr.status, xhr.status === 200 ? 'success' : 'error');
                log('响应: ' + xhr.responseText.substring(0, 100), 'info');

                if (xhr.status === 200) {
                    log('✓ 上传成功!', 'success');
                    loadFiles();
                } else {
                    log('✗ 上传失败', 'error');
                }
            });

            xhr.addEventListener('error', () => {
                log('✗ 网络错误', 'error');
            });

            xhr.open('POST', '/api/upload');
            log('发送POST请求到 /api/upload');
            xhr.send(formData);
        }

        // 加载文件列表
        function loadFiles() {
            fetch('/api/files')
                .then(r => r.json())
                .then(files => {
                    log('获取到 ' + files.length + ' 个文件', 'success');
                    displayFiles(files);
                })
                .catch(e => log('获取文件列表失败: ' + e, 'error'));
        }

        function displayFiles(files) {
            const list = document.getElementById('fileList');
            list.innerHTML = files.map(f => \`
                <div class="file-item">
                    <div>
                        <strong>\${f.name}</strong><br>
                        <small>\${f.size} · \${f.type}</small>
                    </div>
                    <a href="/api/download?id=\${f.id}" style="color: #007bff;">下载</a>
                </div>
            \`).join('');
        }
    </script>
</body>
</html>
''';
  }

  Future<void> _serveStatus(HttpResponse response) async {
    response.headers.contentType = ContentType.json;
    response.write('{"status":"ok","running":$_isRunning,"files":${_uploadedFiles.length}}');
    await response.close();
  }

  Future<void> _serveFiles(HttpResponse response) async {
    response.headers.contentType = ContentType.json;
    response.write(_uploadedFiles.toString());
    await response.close();
  }

  Future<void> _handleUpload(HttpRequest request, HttpResponse response) async {
    print('  → 处理文件上传');

    try {
      final contentType = request.headers.contentType;
      print('  Content-Type: $contentType');

      if (contentType == null) {
        response.statusCode = 400;
        response.write('Missing Content-Type');
        await response.close();
        return;
      }

      final boundary = contentType.parameters['boundary'];
      print('  Boundary: $boundary');

      if (boundary == null) {
        response.statusCode = 400;
        response.write('Missing boundary');
        await response.close();
        return;
      }

      // 读取原始数据
      final bytes = await request.toList();
      final data = bytes.expand((b) => b).toList();
      print('  接收数据大小: ${data.length} bytes');

      if (data.length == 0) {
        print('  ❌ 接收到空数据');
        response.statusCode = 400;
        response.write('Empty data received');
        await response.close();
        return;
      }

      // 获取上传目录
      final uploadDir = await _getUploadDirectory();
      print('  上传目录: ${uploadDir.path}');

      // 确保目录存在
      if (!await uploadDir.exists()) {
        print('  创建上传目录...');
        await uploadDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 尝试从multipart数据中提取文件名
      String filename = 'file_$timestamp';
      try {
        final dataStr = String.fromCharCodes(data);
        final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(dataStr);
        if (filenameMatch != null && filenameMatch.group(1) != null) {
          filename = filenameMatch.group(1)!;
          // 清理文件名
          filename = filename
              .split('/').last
              .split('\\').last
              .replaceAll('..', '')
              .replaceAll('/', '_')
              .replaceAll('\\', '_');
          print('  提取文件名: $filename');
        }
      } catch (e) {
        print('  ⚠ 无法提取文件名，使用默认名称: $filename');
      }

      // 保存文件
      final filePath = '${uploadDir.path}/$filename';
      print('  保存到: $filePath');

      final file = File(filePath);
      await file.writeAsBytes(data);

      // 验证文件是否真的被保存了
      if (await file.exists()) {
        final fileSize = await file.length();
        print('  ✓ 文件已保存: $filename ($fileSize bytes)');
        print('  ✓ 完整路径: ${file.path}');
      } else {
        print('  ❌ 文件保存失败: 文件不存在');
        throw Exception('File was not saved successfully');
      }

      _uploadedFiles.add({
        'id': timestamp.toString(),
        'name': filename,
        'size': '${data.length} bytes',
        'type': 'application/octet-stream',
        'path': file.path,
        'uploadTime': DateTime.now().toIso8601String(),
      });

      print('  ✓ 已添加到文件列表，当前共 ${_uploadedFiles.length} 个文件');

      response.headers.contentType = ContentType.json;
      response.write(_uploadedFiles.last.toString());
      await response.close();
    } catch (e, stackTrace) {
      print('  ❌ 上传失败: $e');
      print('  堆栈: $stackTrace');
      response.statusCode = 500;
      response.write('Error: $e');
      await response.close();
    }
  }

  Future<void> _handleDownload(HttpRequest request, HttpResponse response) async {
    try {
      final id = request.uri.queryParameters['id'];
      if (id == null) {
        response.statusCode = 400;
        await response.close();
        return;
      }

      final fileInfo = _uploadedFiles.firstWhere(
        (file) => file['id'] == id,
        orElse: () => {},
      );

      if (fileInfo.isEmpty) {
        response.statusCode = 404;
        await response.close();
        return;
      }

      final file = File(fileInfo['path'] as String);
      if (!file.existsSync()) {
        response.statusCode = 404;
        await response.close();
        return;
      }

      response.headers.contentType = ContentType.binary;
      response.headers.add('Content-Disposition', 'attachment; filename="${fileInfo['name']}"');
      await response.addStream(file.openRead());
      await response.close();

      print('  ✓ 文件已下载: ${fileInfo['name']}');
    } catch (e) {
      print('  ❌ 下载失败: $e');
      response.statusCode = 500;
      await response.close();
    }
  }

  Future<Directory> _getUploadDirectory() async {
    Directory? uploadDir;

    try {
      // 尝试使用外部存储目录（SD卡）
      if (Platform.isAndroid) {
        try {
          // 获取外部存储目录
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            uploadDir = Directory('${externalDir.path}/WebServiceUploads');
            print('  📱 使用Android外部存储: ${uploadDir.path}');
          }
        } catch (e) {
          print('  ⚠ 无法访问外部存储: $e');
        }
      }

      // iOS使用文档目录
      if (uploadDir == null && Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        uploadDir = Directory('${docDir.path}/Uploads');
        print('  📱 使用iOS文档目录: ${uploadDir.path}');
      }

      // 其他平台或作为后备方案，使用应用文档目录
      if (uploadDir == null) {
        final docDir = await getApplicationDocumentsDirectory();
        uploadDir = Directory('${docDir.path}/Uploads');
        print('  📱 使用应用文档目录: ${uploadDir.path}');
      }

      print('  📂 上传目录: ${uploadDir.path}');

      // 确保目录存在
      if (!await uploadDir.exists()) {
        print('  创建上传目录...');
        await uploadDir.create(recursive: true);
      }

      // 验证目录是否可写
      try {
        final testFile = File('${uploadDir.path}/.write_test');
        await testFile.writeAsBytes([0, 1, 2, 3]);
        await testFile.delete();
        print('  ✓ 目录可写验证通过');
      } catch (e) {
        print('  ❌ 目录不可写: $e');
        print('  💡 提示: 请确保应用有存储权限');
      }

      return uploadDir;
    } catch (e) {
      print('  ❌ 获取上传目录失败: $e');
      // 最后的后备方案：临时目录
      final tempDir = await getTemporaryDirectory();
      uploadDir = Directory('${tempDir.path}/uploads');
      await uploadDir.create(recursive: true);
      print('  ⚠️ 使用临时目录作为后备: ${uploadDir.path}');
      return uploadDir;
    }
  }

  /// 获取上传目录路径（用于显示）
  Future<String> getUploadDirectoryPath() async {
    final dir = await _getUploadDirectory();
    return dir.path;
  }
}
