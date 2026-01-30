import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:calculator_app/models/video_info.dart';
import 'package:calculator_app/services/video_download_service.dart';
import 'package:calculator_app/routes/app_navigation.dart';
import 'package:calculator_app/features/video_download/services/download_history_service.dart';
import 'package:calculator_app/features/video_download/models/downloaded_video_model.dart';
import 'package:calculator_app/widgets/app_background.dart';

/// 视频下载页面
class VideoDownloadPage extends StatefulWidget {
  const VideoDownloadPage({super.key});

  @override
  State<VideoDownloadPage> createState() => _VideoDownloadPageState();
}

class _VideoDownloadPageState extends State<VideoDownloadPage>
    with TickerProviderStateMixin {
  final VideoDownloadService _downloadService = VideoDownloadService();
  final DownloadHistoryService _historyService = DownloadHistoryService();
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _urlFocusNode = FocusNode();

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  VideoInfo? _videoInfo;
  VideoPlayerController? _videoController;
  bool _isParsing = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  CancelToken? _cancelToken;
  String? _errorMessage;
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _initHistoryService();
    _initAnimations();
    _urlFocusNode.addListener(() {
      setState(() {});
    });
  }

  /// 初始化动画
  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  /// 初始化下载历史服务
  Future<void> _initHistoryService() async {
    await _historyService.init();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    _urlFocusNode.dispose();
    _videoController?.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// 解析视频链接
  Future<void> _parseVideoUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入视频链接',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isParsing = true;
      _errorMessage = null;
      _videoInfo = null;
      _videoController?.dispose();
      _videoController = null;
    });

    try {
      final videoInfo = await _downloadService.parseVideoUrl(url);

      if (videoInfo != null) {
        setState(() {
          _videoInfo = videoInfo;
          _isParsing = false;
        });

        // 触发动画
        _scaleController.forward();

        // 滚动到预览区域
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToPreview();
        });

        // 初始化视频播放器
        _initVideoPlayer(videoInfo.videoUrl);
      } else {
        setState(() {
          _isParsing = false;
          _errorMessage = '解析失败，请检查链接是否正确';
        });
        Get.snackbar(
          '错误',
          '解析视频失败，请检查链接',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = '解析失败: $e';
      });
    }
  }

  /// 初始化视频播放器
  Future<void> _initVideoPlayer(String videoUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();
      if (mounted) {
        setState(() {
          _videoController = controller;
        });
      }
    } catch (e) {
      print('初始化视频播放器失败: $e');
    }
  }

  /// 滚动到预览区域
  void _scrollToPreview() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 下载视频
  Future<void> _downloadVideo() async {
    if (_videoInfo == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _cancelToken = CancelToken();
    });

    final fileName = _downloadService.generateSafeFileName(_videoInfo!.title);

    try {
      final file = await _downloadService.downloadVideo(
        _videoInfo!.videoUrl,
        fileName,
        onProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
        cancelToken: _cancelToken,
      );

      if (file != null) {
        // 添加到下载历史
        final fileSize = await file.length();
        final downloadedVideo = DownloadedVideoModel(
          id: '${_videoInfo!.platform ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}',
          title: _videoInfo!.title,
          author: _videoInfo!.author,
          platform: _videoInfo!.platform ?? 'unknown',
          description: _videoInfo!.description,
          coverUrl: _videoInfo!.coverUrl,
          videoUrl: _videoInfo!.videoUrl,
          localPath: file.path,
          fileSize: fileSize,
          downloadedAt: DateTime.now(),
          duration: _videoInfo!.duration,
        );
        await _historyService.addVideo(downloadedVideo);

        setState(() {
          _isDownloading = false;
          _downloadedFile = file;
        });

        Get.snackbar(
          '成功',
          '视频已下载完成',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          mainButton: TextButton(
            onPressed: () => AppNavigation.goToVideoDownloaded(),
            child: const Text('查看'),
          ),
        );
      } else {
        setState(() {
          _isDownloading = false;
        });
        Get.snackbar(
          '失败',
          '下载失败，请重试',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      Get.snackbar(
        '错误',
        '下载失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 取消下载
  void _cancelDownload() {
    if (_cancelToken != null) {
      _downloadService.cancelDownload(_cancelToken!);
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // 自定义 AppBar
              const SizedBox(height: 20,),
              _buildAppBar(),

              // 内容区域
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 支持的平台提示
                        _buildPlatformBanner(),
                        const SizedBox(height: 24),

                        // URL 输入区域
                        _buildUrlInputSection(),
                        const SizedBox(height: 24),

                        // 解析按钮
                        _buildParseButton(),

                        // 错误信息
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorMessage(),
                        ],

                        // 视频信息展示
                        if (_videoInfo != null) ...[
                          const SizedBox(height: 32),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                _buildVideoInfoSection(),
                                const SizedBox(height: 24),
                                _buildVideoPreviewSection(),
                                const SizedBox(height: 24),
                                _buildDownloadSection(),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            const Text(
              '视频下载',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.download_done, color: Colors.white),
              onPressed: () => AppNavigation.goToVideoDownloaded(),
              tooltip: '已下载',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ],
        ),

    );
  }

  /// 构建解析按钮
  Widget _buildParseButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isParsing
              ? [
                  Colors.blue.shade300,
                  Colors.cyan.shade200,
                ]
              : [
                  Colors.blue.shade400,
                  Colors.cyan.shade300,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(_isParsing ? 0.2 : 0.4),
            blurRadius: _isParsing ? 10 : 20,
            offset: const Offset(0, 8),
            spreadRadius: _isParsing ? 0 : 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isParsing ? null : _parseVideoUrl,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            child: Center(
              child: _isParsing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '解析中...',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '解析视频',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建错误信息
  Widget _buildErrorMessage() {
    return AppGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_errorMessage!.contains('抖音')) ...[
            const SizedBox(height: 8),
            Text(
              '💡 抖音链接解析提示：',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '• 确保链接是从抖音App最新复制的\n'
              '• 尝试在抖音App中分享到微信后再复制\n'
              '• 短链接可能展开失败，建议使用完整链接\n'
              '• 检查网络连接是否正常\n'
              '• 如果仍然失败，可能是API服务暂时不可用',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 支持的平台横幅
  Widget _buildPlatformBanner() {
    return AppGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.apps,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '支持的平台',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPlatformChip('抖音', Icons.music_note),
              _buildPlatformChip('TikTok', Icons.music_video),
              _buildPlatformChip('B站', Icons.tv),
              _buildPlatformChip('微博', Icons.wechat),
              _buildPlatformChip('快手', Icons.video_library),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  /// URL 输入区域
  Widget _buildUrlInputSection() {
    final isFocused = _urlFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isFocused ? 0.25 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFocused
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '视频链接',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isFocused ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: '请粘贴抖音、TikTok等平台的视频分享链接...\n\n'
                    '支持平台:\n'
                    '• 抖音 / TikTok\n'
                    '• B站 / 微博 / 快手',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '支持从App直接复制的分享链接',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 视频信息区域
  Widget _buildVideoInfoSection() {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPlatformIcon(_videoInfo!.platform),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getPlatformName(_videoInfo!.platform),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _videoInfo!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '作者: ${_videoInfo!.author}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          if (_videoInfo!.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _videoInfo!.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_videoInfo!.duration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_videoInfo!.duration!),
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 视频预览区域
  Widget _buildVideoPreviewSection() {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '视频预览',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: _buildVideoPlayer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // 点击视频区域直接切换播放/暂停
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // 暂停时显示播放图标
          if (!_videoController!.value.isPlaying)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 下载区域
  Widget _buildDownloadSection() {
    // 下载完成显示文件信息
    if (_downloadedFile != null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.teal.shade300,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '下载完成！',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '文件已成功保存到本地',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 18, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _downloadedFile!.path,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _downloadedFile!.path));
                          Get.snackbar(
                            '已复制',
                            '文件路径已复制到剪贴板',
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green.withOpacity(0.9),
                            colorText: Colors.white,
                          );
                        },
                        tooltip: '复制路径',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _downloadedFile = null;
                      });
                    },
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('重新下载'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (await _downloadedFile!.exists()) {
                        final fileSize = await _downloadedFile!.length();
                        Get.snackbar(
                          '文件信息',
                          '文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
                          duration: const Duration(seconds: 3),
                          backgroundColor: Colors.white.withOpacity(0.95),
                          colorText: Colors.black87,
                        );
                      } else {
                        Get.snackbar(
                          '提示',
                          '文件不存在，可能已被删除',
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    label: const Text('查看信息'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 下载中状态
    if (_isDownloading) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade400,
              Colors.deepOrange.shade300,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '下载中...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _cancelDownload,
              icon: const Icon(Icons.cancel_rounded, color: Colors.white),
              label: const Text(
                '取消下载',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 默认下载按钮
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF009688),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _downloadVideo,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '下载视频',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String? platform) {
    switch (platform) {
      case 'douyin':
        return Icons.music_note;
      case 'tiktok':
        return Icons.music_video;
      case 'bilibili':
        return Icons.tv;
      case 'weibo':
        return Icons.wechat;
      case 'kuaishou':
        return Icons.video_library;
      default:
        return Icons.video_call;
    }
  }

  String _getPlatformName(String? platform) {
    switch (platform) {
      case 'douyin':
        return '抖音';
      case 'tiktok':
        return 'TikTok';
      case 'bilibili':
        return 'B站';
      case 'weibo':
        return '微博';
      case 'kuaishou':
        return '快手';
      default:
        return '未知平台';
    }
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
