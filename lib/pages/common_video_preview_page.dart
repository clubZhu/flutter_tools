import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../features/video_download/models/downloaded_video_model.dart';
import '../models/video_recording_model.dart';
import '../controllers/video_recording_controller.dart';
import 'package:calculator_app/widgets/app_background.dart';

/// 通用视频预览页面
/// 支持已下载视频和录制视频的预览
/// 支持横屏播放和双指缩放
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
  bool _isFullScreen = false; // 是否全屏

  // 缩放控制器
  final TransformationController _transformationController =
      TransformationController();

  // 进度条拖动状态
  bool _isScrubbing = false;
  double _scrubPosition = 0.0;
  final GlobalKey _progressBarKey = GlobalKey();
  bool _wasPlayingBeforeScrubbing = false; // 记录拖动前的播放状态

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
    _transformationController.dispose();
    // 退出时恢复竖屏和系统UI
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
    // 全屏模式下的布局
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _isFullScreen
            ? _buildFullScreenPlayer()
            : _buildNormalPlayer(),
      );
    }

    // 普通模式
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

  Widget _buildNormalPlayer() {
    return AppBackground(
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
          // 横屏/全屏切换按钮
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _toggleFullScreen,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 8),
          // 分享按钮
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareVideo,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          // 删除按钮
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
        // 点击视频区域直接切换播放/暂停
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
            _showControls = true; // 暂停时显示控制栏
          } else {
            _controller!.play();
            _showControls = false; // 播放时隐藏控制栏
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频播放器 - 支持双指缩放
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 3.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

          // 底部控制栏和进度条（暂停时显示，播放时隐藏）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: (!_controller!.value.isPlaying || _showControls) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _buildTikTokStyleProgressBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 分享视频
  Future<void> _shareVideo() async {
    try {
      await Share.shareXFiles(
        [XFile(_videoPath)],
        text: '分享视频',
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '分享失败: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
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

  /// 切换全屏模式
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        // 进入全屏横屏模式
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // 退出全屏，恢复竖屏
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        // 重置缩放
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  /// 构建全屏播放器
  Widget _buildFullScreenPlayer() {
    return GestureDetector(
      onTap: () {
        // 点击视频区域切换播放/暂停
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
            _showControls = true;
          } else {
            _controller!.play();
            _showControls = false;
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频播放器 - 支持双指缩放
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 3.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

          // 顶部控制栏（返回和全屏按钮）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: (!_controller!.value.isPlaying || _showControls) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  children: [
                    // 返回按钮
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (_isFullScreen) {
                          _toggleFullScreen();
                        } else {
                          Get.back();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _videoTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 退出全屏按钮
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: _toggleFullScreen,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部控制栏和进度条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: (!_controller!.value.isPlaying || _showControls) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: _buildTikTokStyleProgressBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据触摸位置更新进度条位置
  void _updateScrubPosition(Offset globalPosition) {
    try {
      final RenderBox? renderBox =
          _progressBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      // 获取进度条的本地坐标
      final localPosition = renderBox.globalToLocal(globalPosition);

      // 计算点击位置相对于进度条宽度的比例
      final double ratio = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);

      // 计算对应的视频时间位置
      final duration = _controller!.value.duration.inMilliseconds.toDouble();
      _scrubPosition = ratio * duration;
    } catch (e) {
      print('更新进度条位置失败: $e');
    }
  }

  /// 构建抖音风格的进度条
  Widget _buildTikTokStyleProgressBar() {
    final position = _isScrubbing
        ? _scrubPosition
        : _controller!.value.position.inMilliseconds.toDouble();
    final duration = _controller!.value.duration.inMilliseconds.toDouble();

    // 获取缓冲进度（buffered 是 List<DurationRange>）
    final buffer = _controller!.value.buffered.isNotEmpty
        ? _controller!.value.buffered.last.end.inMilliseconds.toDouble()
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 进度条和时间预览
        Column(
          children: [
            // 时间预览（拖动时显示大字体的当前时间）
            if (_isScrubbing)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(
                      Duration(milliseconds: position.toInt()),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 自定义进度条
            GestureDetector(
              onHorizontalDragStart: (details) {
                setState(() {
                  _wasPlayingBeforeScrubbing = _controller!.value.isPlaying;
                  _isScrubbing = true;
                  _controller!.pause();
                  _updateScrubPosition(details.globalPosition);
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _updateScrubPosition(details.globalPosition);
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _controller!.seekTo(
                    Duration(milliseconds: _scrubPosition.toInt()),
                  );
                  _isScrubbing = false;
                  // 如果拖动前在播放，则恢复播放
                  if (_wasPlayingBeforeScrubbing) {
                    _controller!.play();
                  }
                });
              },
              onTapDown: (details) {
                setState(() {
                  _wasPlayingBeforeScrubbing = _controller!.value.isPlaying;
                  _isScrubbing = true;
                  _controller!.pause();
                  _updateScrubPosition(details.globalPosition);
                });
              },
              onTapUp: (details) {
                setState(() {
                  _controller!.seekTo(
                    Duration(milliseconds: _scrubPosition.toInt()),
                  );
                  _isScrubbing = false;
                  // 如果点击前在播放，则恢复播放
                  if (_wasPlayingBeforeScrubbing) {
                    _controller!.play();
                  }
                });
              },
              child: Container(
                key: _progressBarKey,
                height: 24, // 增加高度，更易于触摸
                width: double.infinity,
                color: Colors.white.withOpacity(0.1),
                child: CustomPaint(
                  painter: _TikTokProgressBarPainter(
                    position: position,
                    duration: duration,
                    buffer: buffer,
                    isScrubbing: _isScrubbing,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 当前时间/总时间
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                  Duration(milliseconds: position.toInt()),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(_controller!.value.duration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 抖音风格的进度条绘制器
class _TikTokProgressBarPainter extends CustomPainter {
  final double position;
  final double duration;
  final double buffer;
  final bool isScrubbing;

  _TikTokProgressBarPainter({
    required this.position,
    required this.duration,
    required this.buffer,
    required this.isScrubbing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final progress = position / duration;
    final buffered = buffer / duration;

    // 背景轨道（半透明）
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - 2, size.width, 4),
      Radius.circular(2),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 缓冲进度（半透明白色）
    if (buffered > 0) {
      final bufferPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      final bufferRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height / 2 - 2, size.width * buffered, 4),
        Radius.circular(2),
      );
      canvas.drawRRect(bufferRect, bufferPaint);
    }

    // 播放进度（白色，拖动时加粗）
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final progressHeight = isScrubbing ? 6.0 : 3.0; // 拖动时加粗
    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        0,
        size.height / 2 - progressHeight / 2,
        size.width * progress,
        progressHeight,
      ),
      Radius.circular(progressHeight / 2),
    );
    canvas.drawRRect(progressRect, progressPaint);

    // 拖动指示器（拖动时显示的大圆点）
    if (isScrubbing) {
      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final indicatorRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * progress, size.height / 2),
          width: 16,
          height: 16,
        ),
        Radius.circular(8),
      );

      // 添加阴影效果
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawRRect(
        indicatorRect.shift(const Offset(0, 2)), // 阴影偏移
        shadowPaint,
      );
      canvas.drawRRect(indicatorRect, indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(_TikTokProgressBarPainter oldDelegate) {
    return position != oldDelegate.position ||
        duration != oldDelegate.duration ||
        buffer != oldDelegate.buffer ||
        isScrubbing != oldDelegate.isScrubbing;
  }
}
