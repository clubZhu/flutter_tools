import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/downloaded_video_model.dart';

/// 优化的视频缩略图组件
class VideoThumbnail extends StatelessWidget {
  final DownloadedVideoModel video;

  const VideoThumbnail({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    // 优先使用本地缩略图
    if (video.localThumbnailPath.isNotEmpty) {
      return Image.file(
        File(video.localThumbnailPath),
        fit: BoxFit.cover,
        gaplessPlayback: true, // 优化：减少闪烁
        errorBuilder: (context, error, stackTrace) {
          return NetworkThumbnail(video: video);
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    return NetworkThumbnail(video: video);
  }
}

/// 网络缩略图组件
class NetworkThumbnail extends StatelessWidget {
  final DownloadedVideoModel video;

  const NetworkThumbnail({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    if (video.coverUrl.isNotEmpty) {
      return Image.network(
        video.coverUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return const DefaultCover();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    return const DefaultCover();
  }
}

/// 默认封面组件
class DefaultCover extends StatelessWidget {
  const DefaultCover({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.video_library,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}
