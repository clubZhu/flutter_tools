import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../../features/video_download/models/downloaded_video_model.dart';
import '../../models/video_recording_model.dart';
import '../../controllers/video_recording_controller.dart';
import 'package:calculator_app/widgets/app_background.dart';
import 'tiktok_progress_bar_painter.dart';

class CommonVideoPreviewWidget extends StatefulWidget {
  final Widget? child;

  const CommonVideoPreviewWidget({Key? key, this.child}) : super(key: key);

  @override
  State<CommonVideoPreviewWidget> createState() => _CommonVideoPreviewWidgetState();
}

class _CommonVideoPreviewWidgetState extends State<CommonVideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false;
  bool _isFullScreen = false;

  final TransformationController _transformationController = TransformationController();

  bool _isScrubbing = false;
  double _scrubPosition = 0.0;
  final GlobalKey _progressBarKey = GlobalKey();
  bool _wasPlayingBeforeScrubbing = false;

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
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildFullScreenPlayer(),
      );
    }

    if (widget.child != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: widget.child!,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Hero(
                  tag: _heroTag,
                  child: _hasError
                      ? _buildErrorView()
                      : !_isInitialized
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildFullScreenPlayer() {
    return GestureDetector(
      onTap: () {
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
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareVideo,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
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
                Get.back();
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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  void _updateScrubPosition(Offset globalPosition) {
    try {
      final RenderBox? renderBox =
          _progressBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(globalPosition);
      final double ratio = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
      final duration = _controller!.value.duration.inMilliseconds.toDouble();
      _scrubPosition = ratio * duration;
    } catch (e) {
      print('更新进度条位置失败: $e');
    }
  }

  Widget _buildTikTokStyleProgressBar() {
    final position = _isScrubbing
        ? _scrubPosition
        : _controller!.value.position.inMilliseconds.toDouble();
    final duration = _controller!.value.duration.inMilliseconds.toDouble();
    final buffer = _controller!.value.buffered.isNotEmpty
        ? _controller!.value.buffered.last.end.inMilliseconds.toDouble()
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            if (_isScrubbing)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(Duration(milliseconds: position.toInt())),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
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
                  _controller!.seekTo(Duration(milliseconds: _scrubPosition.toInt()));
                  _isScrubbing = false;
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
                  _controller!.seekTo(Duration(milliseconds: _scrubPosition.toInt()));
                  _isScrubbing = false;
                  if (_wasPlayingBeforeScrubbing) {
                    _controller!.play();
                  }
                });
              },
              child: Container(
                key: _progressBarKey,
                height: 24,
                width: double.infinity,
                color: Colors.white.withOpacity(0.1),
                child: CustomPaint(
                  painter: TikTokProgressBarPainter(
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(Duration(milliseconds: position.toInt())),
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
