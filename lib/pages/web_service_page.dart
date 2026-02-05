import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:calculator_app/services/web_service_server.dart';
import 'package:calculator_app/widgets/app_background.dart';

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

    await _server.startServer(port: 8080);

    setState(() {
      _isStarting = false;
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 自定义AppBar
              _buildAppBar(),

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 服务状态卡片
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      // 控制按钮
                      _buildControlButtons(),
                      const SizedBox(height: 20),
                      // 上传文件列表
                      _buildUploadedFilesSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建自定义AppBar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '文件传输服务',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 状态卡片
  Widget _buildStatusCard() {
    return AppGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 呼吸动画指示器
          SizedBox(height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_server.isRunning) ...[
                  // 外圈呼吸效果
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
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
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.4),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                // 中心图标
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _server.isRunning
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_server.isRunning ? Colors.green : Colors.grey).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 3,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _server.isRunning ? Icons.cloud_done : Icons.cloud_off,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 状态文本
          Text(
            _server.isRunning ? '服务运行中' : '服务已停止',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if(_server.isRunning)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      _server.serverUrl??'',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _server.serverUrl??''));
                        Get.snackbar(
                          '已复制',
                          '地址已复制到剪贴板',
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 端口信息
          if(!_server.isRunning)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '端口: ${ '未启动'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 上传目录信息卡片
  Widget _buildUploadDirectoryCard() {
    if (!_server.isRunning) return const SizedBox();

    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storage,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '上传目录',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: _server.getUploadDirectoryPath(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final path = snapshot.data!;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_special,
                          size: 18,
                          color: Colors.orange.shade200,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '文件存储位置',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              path,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: path));
                                Get.snackbar(
                                  '已复制',
                                  '目录路径已复制到剪贴板',
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green.withOpacity(0.9),
                                  colorText: Colors.white,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.orange.shade200,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '这是临时目录，应用卸载或清理后文件会丢失',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 服务地址卡片
  Widget _buildServerAddressCard() {
    final serverUrl = _server.serverUrl;
    if (serverUrl == null) return const SizedBox();

    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wifi,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '局域网访问地址',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 主要地址（系统自动选择的）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '推荐地址',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    serverUrl,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 显示所有可用地址
          if (_allIps.length > 1) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '所有可用地址',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_allIps.where((ip) => !ip.contains('localhost')).map((ip) {
              final ipOnly = ip.split(' ')[0];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          'http://$ipOnly:8080',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: 'http://$ipOnly:8080'));
                            Get.snackbar(
                              '已复制',
                              '地址已复制到剪贴板',
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green.withOpacity(0.9),
                              colorText: Colors.white,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.copy,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.orange.shade200,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '请确保设备在同一WiFi网络，如果无法访问请尝试其他地址',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 控制按钮
  Widget _buildControlButtons() {
    final isRunning = _server.isRunning;
    final isProcessing = _isStarting || _isStopping;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isRunning ? Colors.red : Colors.green).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isProcessing
            ? null
            : isRunning
                ? _stopServer
                : _startServer,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: isRunning ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isRunning ? Icons.stop : Icons.play_arrow, size: 24),
        label: Text(
          isProcessing
              ? (_isStarting ? '启动中...' : '停止中...')
              : (isRunning ? '停止服务' : '启动服务'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 上传文件列表
  Widget _buildUploadedFilesSection() {
    final uploadedFiles = _server.uploadedFiles;

    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_open,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '已上传文件 (${uploadedFiles.length})',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (uploadedFiles.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无上传文件',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '上传的文件将显示在这里',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uploadedFiles.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: Colors.white.withOpacity(0.2),
                  thickness: 1,
                  height: 1,
                ),
              ),
              itemBuilder: (context, index) {
                final file = uploadedFiles[index];
                return _buildFileItem(file);
              },
            ),
        ],
      ),
    );
  }

  /// 文件项
  Widget _buildFileItem(Map<String, dynamic> file) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(file['name']),
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['name'] ?? '未知文件',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.data_usage,
                          size: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${file['size']} · ${file['type']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatUploadTime(file['uploadTime']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showFileDetails(file),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 存储位置
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open,
                  size: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file['path'] ?? '',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: file['path'] ?? ''));
                      Get.snackbar(
                        '已复制',
                        '文件路径已复制到剪贴板',
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green.withOpacity(0.9),
                        colorText: Colors.white,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(file['name']),
                color: Colors.indigo,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '文件详情',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('文件名', file['name']),
              _buildDetailRow('大小', file['size']),
              _buildDetailRow('类型', file['type']),
              _buildDetailRow('上传时间', _formatUploadTime(file['uploadTime'])),
              const SizedBox(height: 12),
              const Text(
                '存储位置:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
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
                          backgroundColor: Colors.green.withOpacity(0.9),
                          colorText: Colors.white,
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '关闭',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
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
