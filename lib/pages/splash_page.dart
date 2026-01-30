import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/routes/app_routes.dart';

/// 启动页
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initialize();
  }

  void _initAnimations() {
    // Logo 动画控制器
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 文字动画控制器
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Logo 缩放动画
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo 淡入动画
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // 文字淡入动画
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // 文字滑入动画
    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // 脉冲动画
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 启动动画序列
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  Future<void> _initialize() async {
    // 直接跳过生物识别检查，快速进入应用
    await Future.delayed(const Duration(milliseconds: 1500));
    _navigateToHome();
  }

  void _navigateToHome() {
    Get.offAllNamed(AppRoutes.INITIAL);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade400,
              Colors.blue.shade400,
              Colors.cyan.shade300,
            ],
          ),
        ),
        child: Stack(
          children: [
            // 装饰性背景元素
            _buildBackgroundDecorations(),
            // 主要内容
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo 动画
                    _buildLogoAnimation(),
                    const SizedBox(height: 48),

                    // 应用名称动画
                    _buildTitleAnimation(),
                    const SizedBox(height: 16),

                    // 副标题动画
                    _buildSubtitleAnimation(),
                    const SizedBox(height: 64),

                    // 加载指示器
                    _buildLoadingIndicator(),
                    const SizedBox(height: 24),

                    // 状态文字
                    _buildStatusText(),
                  ],
                ),
              ),
            ),
            // 版本号
            _buildVersionLabel(),
          ],
        ),
      ),
    );
  }

  /// 背景装饰元素
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // 左上角圆形
        Positioned(
          top: -50,
          left: -50,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ),
        // 右下角圆形
        Positioned(
          bottom: -80,
          right: -80,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.5 - _pulseAnimation.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              );
            },
          ),
        ),
        // 左下角小圆形
        Positioned(
          bottom: 100,
          left: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        // 右上角小圆形
        Positioned(
          top: 150,
          right: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  /// Logo 动画
  Widget _buildLogoAnimation() {
    return AnimatedBuilder(
      animation: _logoScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoFadeAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.apps_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 标题动画
  Widget _buildTitleAnimation() {
    return AnimatedBuilder(
      animation: _textFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _textFadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _textSlideAnimation.value),
            child: const Text(
              '多功能工具箱',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 副标题动画
  Widget _buildSubtitleAnimation() {
    return AnimatedBuilder(
      animation: _textFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _textFadeAnimation.value * 0.8,
          child: Transform.translate(
            offset: Offset(0, _textSlideAnimation.value * 1.2),
            child: Text(
              'Multi-Purpose Toolbox',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 2.0,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 加载指示器
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),
          );
        },
      ),
    );
  }

  /// 状态文字
  Widget _buildStatusText() {
    return AnimatedBuilder(
      animation: _textFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _textFadeAnimation.value,
          child: Text(
            '正在启动...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
        );
      },
    );
  }

  /// 版本号标签
  Widget _buildVersionLabel() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _textFadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _textFadeAnimation.value * 0.6,
              child: Text(
                'Version 2.1.2',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
