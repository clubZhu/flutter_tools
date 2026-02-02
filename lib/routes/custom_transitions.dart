import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 自定义页面转场动画
class CustomTransitions {
  CustomTransitions._();

  /// 淡入缩放动画 - 适用于大多数页面
  static GetPage customFadeZoom({
    required GetPage page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return GetPage(
      name: page.name,
      page: page.page,
      binding: page.binding,
      transitionDuration: duration,
      transition: Transition.fadeIn,
      curve: curve,
    );
  }

  /// 从右侧滑入并淡入 - 适用于常规页面
  static GetPage customSlideFade({
    required GetPage page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return GetPage(
      name: page.name,
      page: page.page,
      binding: page.binding,
      transitionDuration: duration,
      transition: Transition.rightToLeft,
      curve: curve,
    );
  }

  /// 从底部滑入并淡入 - 适用于模态页面
  static GetPage customBottomSlideFade({
    required GetPage page,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) {
    return GetPage(
      name: page.name,
      page: page.page,
      binding: page.binding,
      transitionDuration: duration,
      transition: Transition.downToUp,
      curve: curve,
    );
  }
}

/// 自定义转场 Widget
class CustomFadeZoomTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const CustomFadeZoomTransition({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 淡入动画
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    // 缩放动画
    final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }
}

/// 自定义滑动淡入转场 Widget
class CustomSlideFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const CustomSlideFadeTransition({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 滑动动画
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    // 淡入动画
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

/// 自定义底部滑动淡入转场 Widget
class CustomBottomSlideFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const CustomBottomSlideFadeTransition({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 从底部滑动动画
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    // 淡入动画
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}
