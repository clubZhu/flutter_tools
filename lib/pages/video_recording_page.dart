import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../controllers/video_recording_controller.dart';

/// 视频录制页面
class VideoRecordingPage extends StatefulWidget {
  const VideoRecordingPage({Key? key}) : super(key: key);

  @override
  State<VideoRecordingPage> createState() => _VideoRecordingPageState();
}

class _VideoRecordingPageState extends State<VideoRecordingPage> {
  late final VideoRecordingController _controller;

  @override
  void initState() {
    super.initState();
    // 获取或创建控制器
    if (Get.isRegistered<VideoRecordingController>()) {
      _controller = Get.find<VideoRecordingController>();
    } else {
      _controller = Get.put(VideoRecordingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // 监听相机切换计数器以触发 UI 刷新
        _controller.cameraChangeCounter.value;
        
        if (_controller.hasError.value) {
          return _buildErrorView();
        }

        if (!_controller.isInitialized.value) {
          return _buildLoadingView();
        }

        return _buildCameraView();
      }),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            '正在初始化相机...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _controller.errorMessage.value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('返回', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建相机视图
  Widget _buildCameraView() {
    return Stack(
      children: [
        // 相机预览
        Center(
          child: CameraPreview(_controller.cameraController!),
        ),

        // 顶部工具栏
        _buildTopToolbar(),

        // 底部控制栏
        _buildBottomControls(),
      ],
    );
  }

  /// 构建顶部工具栏
  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 返回按钮
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(12),
              ),

              // 录制时长显示
              Expanded(
                child: Center(
                  child: Obx(() {
                    if (!_controller.isRecording.value) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _controller.formattedDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // 查看历史按钮
              IconButton(
                onPressed: () => Get.toNamed('/video-history'),
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 28,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建底部控制栏
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 切换相机按钮
              IconButton(
                onPressed: _controller.switchCamera,
                icon: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 32,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(16),
              ),

              // 录制按钮
              Expanded(
                child: Center(
                  child: Obx(() {
                    final isRecording = _controller.isRecording.value;
                    return _AnimatedRecordButton(
                      isRecording: isRecording,
                      onStartRecording: _controller.startRecording,
                      onStopRecording: _controller.stopRecording,
                    );
                  }),
                ),
              ),

              // 占位（保持布局平衡）
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// 带动画效果的录制按钮
/// 带动画效果的录制按钮
class _AnimatedRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _AnimatedRecordButton({
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<_AnimatedRecordButton> createState() => _AnimatedRecordButtonState();
}

class _AnimatedRecordButtonState extends State<_AnimatedRecordButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _morphController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _morphAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // 点击缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    // 录制时脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 形状变形动画控制器
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 颜色过渡动画
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(_morphController);
  }

  @override
  void didUpdateWidget(_AnimatedRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 当开始录制时
    if (widget.isRecording && !oldWidget.isRecording) {
      _morphController.forward();
      _pulseController.repeat(reverse: true);
    } 
    // 当停止录制时
    else if (!widget.isRecording && oldWidget.isRecording) {
      _morphController.reverse();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // 播放点击缩放动画
    await _scaleController.forward();
    await _scaleController.reverse();

    // 执行回调
    if (widget.isRecording) {
      widget.onStopRecording();
    } else {
      widget.onStartRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation, 
          _pulseAnimation, 
          _morphAnimation,
        ]),
        builder: (context, child) {
          // 计算缩放：点击缩放 + 录制时脉冲
          final scale = _scaleAnimation.value *
              (widget.isRecording ? _pulseAnimation.value : 1.0);

          // 计算内圈大小：从64渐变到32
          final innerSize = 64 - (32 * _morphAnimation.value);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _colorAnimation.value ?? Colors.white,
                  width: 4,
                ),
                boxShadow: widget.isRecording
                    ? [
                        // 外发光效果
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                        // 内部阴影
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : [
                        // 未录制时的阴影
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value ?? Colors.white,
                    shape: BoxShape.circle,
                    // 添加内部阴影效果
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // 使用AnimatedSwitcher添加平滑过渡
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: widget.isRecording
                        ? Container(
                            key: const ValueKey('recording'),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('idle'),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
