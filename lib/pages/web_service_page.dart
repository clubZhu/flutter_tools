import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:calculator_app/services/web_service_server.dart';

/// WebService文件传输页面
class WebServicePage extends StatefulWidget {
  const WebServicePage({super.key});

  @override
  State<WebServicePage> createState() => _WebServicePageState();
}

class _WebServicePageState extends State<WebServicePage>
    with SingleTickerProviderStateMixin {
  final WebServiceServer _server = WebServiceServer();
  bool _isStarting = false;
  bool _isStopping = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  List<String> _allIps = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initServer();
    _getAllIps();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 初始化动画
  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// 初始化服务器
  Future<void> _initServer() async {
    await _server.init();
    setState(() {}); // 刷新UI显示获取到的IP
  }

  /// 获取所有可用的IP地址
  Future<void> _getAllIps() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      final ips = <String>[];

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // 使用类型名称比较IPv4
          if ((addr.type.name == 'IPv4' || addr.type == InternetAddressType.any) &&
              !addr.address.startsWith('127.')) {
            ips.add('${addr.address} (${interface.name})');
          }
        }
      }

      // 添加localhost
      ips.add('localhost (本机)');

      if (mounted) {
        setState(() {
          _allIps = ips;
        });
      }
    } catch (e) {
      print('获取IP列表失败: $e');
      if (mounted) {
        setState(() {
          _allIps = ['localhost (本机)'];
        });
      }
    }
  }

  /// 启动定时刷新
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _server.isRunning) {
        setState(() {}); // 刷新UI以显示最新的上传文件列表
      }
    });
  }

  /// 启动服务器
  Future<void> _startServer() async {
    setState(() {
      _isStarting = true;
    });

    final success = await _server.startServer(port: 8080);

    setState(() {
      _isStarting = false;
    });

    if (success && mounted) {
      Get.snackbar(
        '成功',
        '服务器已启动',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
      );
    } else if (mounted) {
      Get.snackbar(
        '失败',
        '服务器启动失败',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  /// 停止服务器
  Future<void> _stopServer() async {
    setState(() {
      _isStopping = true;
    });

    final success = await _server.stopServer();

    setState(() {
      _isStopping = false;
    });

    if (success && mounted) {
      Get.snackbar(
        '成功',
        '服务器已停止',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('文件传输服务'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 服务状态卡片
            _buildStatusCard(),
            const SizedBox(height: 20),

            // 服务地址卡片
            if (_server.isRunning) ...[
              _buildServerAddressCard(),
              const SizedBox(height: 20),
              _buildUploadDirectoryCard(),
              const SizedBox(height: 20),
            ],

            // 控制按钮
            _buildControlButtons(),
            const SizedBox(height: 20),

            // 上传文件列表
            _buildUploadedFilesSection(),
          ],
        ),
      ),
    );
  }

  /// 状态卡片
  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 呼吸动画指示器
            Stack(
              alignment: Alignment.center,
              children: [
                if (_server.isRunning) ...[
                  // 外圈呼吸效果
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  // 中圈呼吸效果
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
                // 中心图标
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _server.isRunning
                        ? Colors.green
                        : Colors.grey[400],
                  ),
                  child: Icon(
                    _server.isRunning ? Icons.cloud_done : Icons.cloud_off,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 状态文本
            Text(
              _server.isRunning ? '服务运行中' : '服务已停止',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _server.isRunning ? Colors.green : Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),

            // 端口信息
            Text(
              '端口: ${_server.isRunning ? '8080' : '未启动'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 上传目录信息卡片
  Widget _buildUploadDirectoryCard() {
    if (!_server.isRunning) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '上传目录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: _server.getUploadDirectoryPath(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final path = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '文件存储位置',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  path,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: path));
                              Get.snackbar(
                                '已复制',
                                '目录路径已复制到剪贴板',
                                duration: const Duration(seconds: 2),
                              );
                            },
                            tooltip: '复制路径',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ 这是临时目录，应用卸载或清理后文件会丢失',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 服务地址卡片
  Widget _buildServerAddressCard() {
    final serverUrl = _server.serverUrl;
    if (serverUrl == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '局域网访问地址',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 主要地址（系统自动选择的）
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '推荐地址',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    serverUrl,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // 显示所有可用地址
            if (_allIps.length > 1) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '所有可用地址',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_allIps.where((ip) => !ip.contains('localhost')).map((ip) {
                final ipOnly = ip.split(' ')[0];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            'http://$ipOnly:8080',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            // 复制地址
                          },
                          tooltip: '复制',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()),
            ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请确保设备在同一WiFi网络，如果无法访问请尝试其他地址',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 控制按钮
  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _server.isRunning || _isStarting
                ? null
                : _startServer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: _isStarting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isStarting ? '启动中...' : '启动服务'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !_server.isRunning || _isStopping
                ? null
                : _stopServer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: _isStopping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.stop),
            label: Text(_isStopping ? '停止中...' : '停止服务'),
          ),
        ),
      ],
    );
  }

  /// 上传文件列表
  Widget _buildUploadedFilesSection() {
    final uploadedFiles = _server.uploadedFiles;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '已上传文件 (${uploadedFiles.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (uploadedFiles.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无上传文件',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uploadedFiles.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final file = uploadedFiles[index];
                  return _buildFileItem(file);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 文件项
  Widget _buildFileItem(Map<String, dynamic> file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFileIcon(file['name']),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file['name'] ?? '未知文件',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${file['size']} · ${file['type']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatUploadTime(file['uploadTime']),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showFileDetails(file),
                  tooltip: '详情',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 存储位置
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file['path'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: file['path'] ?? ''));
                      Get.snackbar(
                        '已复制',
                        '文件路径已复制到剪贴板',
                        duration: const Duration(seconds: 2),
                      );
                    },
                    tooltip: '复制路径',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化上传时间
  String _formatUploadTime(String? uploadTime) {
    if (uploadTime == null) return '';
    try {
      final dt = DateTime.parse(uploadTime);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return '刚刚';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}分钟前';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}小时前';
      } else {
        return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return uploadTime;
    }
  }

  /// 显示文件详情
  void _showFileDetails(Map<String, dynamic> file) {
    Get.dialog(
      AlertDialog(
        title: const Text('文件详情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('文件名', file['name']),
              _buildDetailRow('大小', file['size']),
              _buildDetailRow('类型', file['type']),
              _buildDetailRow('上传时间', _formatUploadTime(file['uploadTime'])),
              const SizedBox(height: 8),
              const Text('存储位置:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        file['path'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: file['path'] ?? ''));
                        Get.back();
                        Get.snackbar(
                          '已复制',
                          '文件路径已复制',
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 详情行
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }

  /// 获取文件图标
  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;

    final ext = fileName.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
}
