import 'package:flutter/material.dart';

/// 抖音风格的进度条绘制器
class TikTokProgressBarPainter extends CustomPainter {
  final double position;
  final double duration;
  final double buffer;
  final bool isScrubbing;

  TikTokProgressBarPainter({
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
  bool shouldRepaint(TikTokProgressBarPainter oldDelegate) {
    return position != oldDelegate.position ||
        duration != oldDelegate.duration ||
        buffer != oldDelegate.buffer ||
        isScrubbing != oldDelegate.isScrubbing;
  }
}
