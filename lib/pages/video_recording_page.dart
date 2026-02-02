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

class _VideoRecordingPageState extends State<VideoRecordingPage>
    with TickerProviderStateMixin {
  late final VideoRecordingController _controller;

  // 页面初始化动画
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // 获取或创建控制器
    if (Get.isRegistered<VideoRecordingController>()) {
      _controller = Get.find<VideoRecordingController>();
    } else {
      _controller = Get.put(VideoRecordingController());
    }

    // 初始化页面动画
    _initPageAnimations();
  }

  /// 初始化页面动画
  void _initPageAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 启动动画
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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

  /// 构建加载视图 - 三个呼吸圆点动画
  Widget _buildLoadingView() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: SizedBox(
                width: 100,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 第一个圆点
                    _buildBreathingDot(0),
                    // 第二个圆点
                    _buildBreathingDot(1),
                    // 第三个圆点
                    _buildBreathingDot(2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建呼吸圆点
  Widget _buildBreathingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // 为每个圆点添加延迟，产生波浪效果
        final delayedValue = ((value * 3) - index).clamp(0.0, 1.0);
        final scale = 0.6 + 0.4 * (1 - (2 * delayedValue - 1).abs());

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6 + 0.4 * delayedValue),
            ),
          ),
        );
      },
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
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // 相机预览
                Center(
                  child: Obx(() {
                    // 监听相机切换以刷新预览
                    _controller.cameraChangeCounter.value;
                    return CameraPreview(_controller.cameraController!);
                  }),
                ),

                // 切换相机时的叠加动画
                Obx(() {
                  if (!_controller.isSwitchingCamera.value) {
                    return const SizedBox.shrink();
                  }
                  return _buildCameraSwitchingOverlay();
                }),

                // 顶部工具栏
                _buildTopToolbar(),

                // 底部控制栏
                _buildBottomControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建相机切换叠加动画
  Widget _buildCameraSwitchingOverlay() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withOpacity(0.3 * value),
          child: Center(
            child: Transform.scale(
              scale: 0.6 + (0.4 * value),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈旋转动画 - 逆时针
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, rotationValue, child) {
                        return RotationTransition(
                          turns: AlwaysStoppedAnimation(rotationValue * 0.5),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3 * value),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // 中圈旋转动画 - 顺时针
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, rotationValue, child) {
                        return RotationTransition(
                          turns: AlwaysStoppedAnimation(-rotationValue * 0.8),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5 * value),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    // 内圈脉冲动画
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, pulseValue, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * (1 - (2 * pulseValue - 1).abs())),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.7 * value),
                                  Colors.white.withOpacity(0.3 * value),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
              _buildAnimatedIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Get.back(),
              ),

              // 录制时长显示
              Expanded(
                child: Center(
                  child: Obx(() {
                    // 监听录制状态和时长，确保时长能实时更新
                    _controller.recordingDuration.value;
                    if (!_controller.isRecording.value) {
                      return const SizedBox.shrink();
                    }
                    return _buildRecordingIndicator();
                  }),
                ),
              ),

              // 查看历史按钮
              _buildAnimatedIconButton(
                icon: Icons.photo_library,
                onPressed: () => Get.toNamed('/video-history'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建录制时长指示器
  Widget _buildRecordingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
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
          ),
        );
      },
    );
  }

  /// 构建带动画的图标按钮
  Widget _buildAnimatedIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: FadeTransition(
            opacity: AlwaysStoppedAnimation(value),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white, size: 28),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        );
      },
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
              _buildCameraSwitchButton(),

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

  /// 构建带旋转动画的相机切换按钮
  Widget _buildCameraSwitchButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: FadeTransition(
            opacity: AlwaysStoppedAnimation(value),
            child: Obx(() {
              final isRecording = _controller.isRecording.value;
              final isSwitching = _controller.isSwitchingCamera.value;
              final isEnabled = !isRecording && !isSwitching;

              return GestureDetector(
                onTap: isEnabled ? _controller.switchCamera : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isEnabled ? 1.0 : 0.4,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        isEnabled ? 0.15 : 0.05,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          isEnabled ? 0.3 : 0.1,
                        ),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white.withOpacity(
                            isEnabled ? 1.0 : 0.5,
                          ),
                          size: 32,
                        ),
                        // 切换中的加载指示器
                        if (isSwitching)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

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
  late AnimationController _tapController;
  late AnimationController _pulseController;
  late AnimationController _morphController;
  late AnimationController _glowController;

  late Animation<double> _tapScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _morphAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 点击反馈动画控制器 - 多阶段弹性动画
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 创建弹性缩放序列：按下->回弹-> overshoot

    _tapScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
          .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.08)
          .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_tapController);

    // 录制时脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 形状变形动画控制器
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );

    // 颜色过渡动画
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(_morphController);

    // 光晕动画控制器
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didUpdateWidget(_AnimatedRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当开始录制时
    if (widget.isRecording && !oldWidget.isRecording) {
      _morphController.forward();
      _glowController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _pulseController.repeat(reverse: true);
        }
      });
    }
    // 当停止录制时
    else if (!widget.isRecording && oldWidget.isRecording) {
      _morphController.reverse();
      _glowController.reverse();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _tapController.dispose();
    _pulseController.dispose();
    _morphController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // 播放弹性点击动画
    await _tapController.forward();
    _tapController.reset();

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
          _tapScaleAnimation,
          _pulseAnimation,
          _morphAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          // 计算缩放：点击弹性缩放 + 录制时脉冲
          final baseScale = widget.isRecording
              ? (_tapScaleAnimation.value * _pulseAnimation.value)
              : _tapScaleAnimation.value;

          // 计算内圈大小：从64平滑渐变到28
          final innerSize = widget.isRecording
              ? 64.0 - (36.0 * _morphAnimation.value)
              : 64.0;

          // 边框宽度动态变化
          final borderWidth = 4.0 + (2.0 * _morphAnimation.value);

          return Transform.scale(
            scale: baseScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _colorAnimation.value ?? Colors.white,
                  width: borderWidth,
                ),
                boxShadow: widget.isRecording
                    ? [
                        // 主外发光效果
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5 * _glowAnimation.value),
                          blurRadius: 30,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                        // 第二层光晕
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        // 内部光晕
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        // 未录制时的柔和阴影
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈光晕层（仅录制时显示）
                    if (widget.isRecording)
                      Container(
                        width: innerSize + 20,
                        height: innerSize + 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.1 * _glowAnimation.value),
                        ),
                      ),

                    // 主按钮
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        color: _colorAnimation.value ?? Colors.white,
                        shape: BoxShape.circle,
                        // 添加立体感阴影
                        boxShadow: [
                          // 内阴影效果
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              widget.isRecording ? 0.15 : 0.1
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          // 外阴影效果
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: widget.isRecording
                            ? Container(
                                key: const ValueKey('recording'),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('idle'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
