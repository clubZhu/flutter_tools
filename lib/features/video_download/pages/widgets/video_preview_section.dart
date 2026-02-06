import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:calculator_app/widgets/app_background.dart';
import '../../controllers/video_download_controller.dart';

/// 视频预览区域
class VideoPreviewSection extends StatelessWidget {
  const VideoPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadController>();

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '视频预览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: _VideoPlayerWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 视频播放器组件
class _VideoPlayerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadController>();

    return Obx(() {
      final videoController = controller.videoController.value;

      if (videoController == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (!videoController.value.isInitialized) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return GestureDetector(
        onTap: controller.toggleVideoPlayback,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoController.value.size.width,
                height: videoController.value.size.height,
                child: VideoPlayer(videoController),
              ),
            ),
            // 暂停时显示播放图标
            if (!videoController.value.isPlaying)
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
          ],
        ),
      );
    });
  }
}
