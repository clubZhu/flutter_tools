import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用通用背景Widget
/// 与首页保持一致的紫蓝青渐变背景
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool gradientBackground;

  const AppBackground({
    super.key,
    required this.child,
    this.gradientBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    // 设置边到边模式，让背景延伸到系统栏下方
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final content = gradientBackground
        ? Container(
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
            child: child,
          )
        : child;

    return content;
  }
}

/// 应用通用卡片样式
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isHighlight;
  final Color? highlightColor;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.isHighlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isHighlight ? Colors.white : Colors.white.withOpacity(0.95);
    final effectiveHighlightColor = highlightColor ?? Colors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isHighlight
                ? [
                    BoxShadow(
                      color: effectiveHighlightColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 应用通用半透明卡片
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
