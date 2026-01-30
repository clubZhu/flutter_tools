import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../features/video_download/models/downloaded_video_model.dart';
import '../models/video_recording_model.dart';
import '../controllers/video_recording_controller.dart';
import 'package:calculator_app/widgets/app_background.dart';

/// 通用视频预览页面
/// 支持已下载视频和录制视频的预览
class CommonVideoPreviewPage extends StatefulWidget {
  const CommonVideoPreviewPage({Key? key}) : super(key: key);

  @override
  State<CommonVideoPreviewPage> createState() => _CommonVideoPreviewPageState();
}

class _CommonVideoPreviewPageState extends State<CommonVideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false;

  // 视频数据
  dynamic _video;
  bool _isRecordingVideo = false;

  String get _videoId => _isRecordingVideo ? _video.id : _video.id;
  String get _videoTitle => _isRecordingVideo ? _video.name : _video.title;
  String get _videoSubtitle => _isRecordingVideo
      ? '${_video.durationFormatted} · ${_video.fileSizeFormatted}'
      : '${_video.author} · ${_video.durationFormatted}';
  String get _videoPath => _isRecordingVideo ? _video.filePath : _video.localPath;
  String get _heroTag => _isRecordingVideo
      ? 'recording_cover_${_video.id}'
      : 'video_cover_${_video.id}';

  @override
  void initState() {
    super.initState();
    _parseArguments();
    _initializeVideo();
  }

  void _parseArguments() {
    final arguments = Get.arguments;
    if (arguments is VideoRecordingModel) {
      _video = arguments;
      _isRecordingVideo = true;
    } else if (arguments is DownloadedVideoModel) {
      _video = arguments;
      _isRecordingVideo = false;
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(_videoPath);
      if (await file.exists()) {
        _controller = VideoPlayerController.file(file);
        await _controller!.initialize();

        _controller!.addListener(() {
          if (mounted) setState(() {});
        });

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller!.play();
        }
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours);
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 自定义AppBar
              _buildAppBar(),

              // 视频播放区域
              Expanded(
                child: Hero(
                  tag: _heroTag,
                  child: _hasError
                      ? _buildErrorView()
                      : !_isInitialized
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _buildVideoPlayer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _videoTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _videoSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 分享按钮
          if (_isRecordingVideo)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareRecordingVideo,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.link, color: Colors.white),
              onPressed: _copyVideoLink,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          // 删除按钮（仅录制视频）
          if (_isRecordingVideo)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _showDeleteDialog,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '视频加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '文件不存在或已被删除',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频播放器
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // 暂停时显示播放图标
          if (!_controller!.value.isPlaying && !_showControls)
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

          // 底部控制栏和进度条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 进度条
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.blue,
                        bufferedColor: Colors.white.withOpacity(0.3),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 控制按钮行
                    Row(
                      children: [
                        // 播放/暂停按钮
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_controller!.value.isPlaying) {
                                _controller!.pause();
                              } else {
                                _controller!.play();
                              }
                            });
                          },
                          child: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 时间显示
                        Expanded(
                          child: Text(
                            '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制视频链接（已下载视频）
  void _copyVideoLink() {
    Clipboard.setData(ClipboardData(text: _video.videoUrl));
    Get.snackbar(
      '已复制',
      '视频链接已复制到剪贴板',
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  /// 分享录制视频
  void _shareRecordingVideo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('分享视频'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text('复制文件路径'),
              subtitle: Text(
                _videoPath,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: _videoPath));
                Get.back();
                Get.snackbar(
                  '已复制',
                  '文件路径已复制到剪贴板',
                  backgroundColor: Colors.green.withOpacity(0.9),
                  colorText: Colors.white,
                );
              },
            ),
          ],
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

  /// 显示删除确认对话框（录制视频）
  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('确认删除'),
        content: Text('确定要删除视频 "$_videoTitle" 吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final controller = Get.find<VideoRecordingController>();
                await controller.deleteVideo(_videoId);
                Get.back();
                Get.back(); // 关闭预览页面
                Get.snackbar(
                  '成功',
                  '视频已删除',
                  backgroundColor: Colors.green.withOpacity(0.9),
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar(
                  '错误',
                  '删除视频失败: $e',
                  backgroundColor: Colors.red.withOpacity(0.9),
                  colorText: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
