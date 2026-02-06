import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/routes/app_navigation.dart';
import '../../controllers/video_download_controller.dart';

/// 自定义 AppBar
class VideoDownloadAppBar extends StatelessWidget {
  const VideoDownloadAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          const Text(
            '视频下载',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.download_done, color: Colors.white),
            onPressed: () => AppNavigation.goToVideoDownloaded(),
            tooltip: '已下载',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
