import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:calculator_app/models/video_info.dart';
import 'package:calculator_app/services/video_download_service.dart';

/// 视频下载页面
class VideoDownloadPage extends StatefulWidget {
  const VideoDownloadPage({super.key});

  @override
  State<VideoDownloadPage> createState() => _VideoDownloadPageState();
}

class _VideoDownloadPageState extends State<VideoDownloadPage> {
  final VideoDownloadService _downloadService = VideoDownloadService();
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  VideoInfo? _videoInfo;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isParsing = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  CancelToken? _cancelToken;
  String? _errorMessage;
  File? _downloadedFile; // 下载的文件

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    _videoController?.dispose();
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
        setState(() {
          _isDownloading = false;
          _downloadedFile = file;
        });

        Get.snackbar(
          '成功',
          '视频已下载完成',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('视频下载'),
        actions: [
          // 历史记录按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.snackbar(
                '提示',
                '历史记录功能开发中',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 支持的平台提示
            _buildPlatformBanner(),
            const SizedBox(height: 20),

            // URL 输入区域
            _buildUrlInputSection(),
            const SizedBox(height: 20),

            // 解析按钮
            ElevatedButton(
              onPressed: _isParsing ? null : _parseVideoUrl,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isParsing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('解析视频', style: TextStyle(fontSize: 16)),
            ),

            // 错误信息
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage!.contains('抖音')) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💡 抖音链接解析提示：',
                        style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 确保链接是从抖音App最新复制的\n'
                        '• 尝试在抖音App中分享到微信后再复制\n'
                        '• 短链接可能展开失败，建议使用完整链接\n'
                        '• 检查网络连接是否正常\n'
                        '• 如果仍然失败，可能是API服务暂时不可用',
                        style: TextStyle(color: Colors.red[600], fontSize: 11, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // 视频信息展示
            if (_videoInfo != null) ...[
              const SizedBox(height: 24),
              _buildVideoInfoSection(),
              const SizedBox(height: 20),
              _buildVideoPreviewSection(),
              const SizedBox(height: 20),
              _buildDownloadSection(),
            ],
          ],
        ),
      ),
    );
  }

  /// 支持的平台横幅
  Widget _buildPlatformBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '支持的平台',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  /// URL 输入区域
  Widget _buildUrlInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '视频链接',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '请粘贴抖音、TikTok等平台的视频分享链接...\n\n例如:\nhttps://v.douyin.com/xxxxx/\nhttps://www.tiktok.com/@user/video/xxxxx',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '支持从应用复制的分享链接',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  /// 视频信息区域
  Widget _buildVideoInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPlatformIcon(_videoInfo!.platform),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getPlatformName(_videoInfo!.platform),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _videoInfo!.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '作者: ${_videoInfo!.author}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            if (_videoInfo!.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _videoInfo!.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_videoInfo!.duration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_videoInfo!.duration!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 视频预览区域
  Widget _buildVideoPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '视频预览',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: _buildVideoPlayer(),
              ),
            ),
          ],
        ),
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

    return Stack(
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
        // 播放按钮
        Positioned(
          child: IconButton(
            iconSize: 64,
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  /// 下载区域
  Widget _buildDownloadSection() {
    // 下载完成显示文件信息
    if (_downloadedFile != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '下载完成！',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '文件已保存到以下位置',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _downloadedFile!.path,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _downloadedFile!.path));
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _downloadedFile = null;
                        });
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('重新下载'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // 检查文件是否存在
                        if (await _downloadedFile!.exists()) {
                          final fileSize = await _downloadedFile!.length();
                          Get.snackbar(
                            '文件信息',
                            '文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
                            duration: const Duration(seconds: 3),
                          );
                        } else {
                          Get.snackbar(
                            '提示',
                            '文件不存在，可能已被删除',
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('查看信息'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 下载中状态
    if (_isDownloading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '下载中...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _cancelDownload,
                icon: const Icon(Icons.cancel),
                label: const Text('取消下载'),
              ),
            ],
          ),
        ),
      );
    }

    // 默认下载按钮
    return ElevatedButton.icon(
      onPressed: _downloadVideo,
      icon: const Icon(Icons.download),
      label: const Text('下载视频'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
