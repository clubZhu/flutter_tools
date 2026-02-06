import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:calculator_app/widgets/app_background.dart';
import '../../controllers/video_download_controller.dart';

/// 下载区域组件
class DownloadSection extends StatelessWidget {
  const DownloadSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadController>();

    return Obx(() {
      // 图片下载中状态
      if (controller.isDownloadingImages.value) {
        return _ImageDownloadingWidget(
          progress: controller.imageDownloadProgress.value,
          currentIndex: controller.currentImageIndex.value,
          total: controller.videoInfo.value?.images.length ?? 0,
          onCancel: controller.cancelDownload,
        );
      }

      // 视频下载完成状态，显示图片下载按钮
      if (controller.downloadedFile.value != null) {
        return _DownloadCompletedWithImages(
          file: controller.downloadedFile.value!,
          hasImages: controller.videoInfo.value?.images.isNotEmpty ?? false,
          imagesDownloaded: controller.downloadedImages.isNotEmpty,
          onDownloadImages: controller.downloadImages,
          onReset: controller.resetDownloadState,
        );
      }

      // 视频下载中状态
      if (controller.isDownloading.value) {
        return _DownloadingWidget(
          progress: controller.downloadProgress.value,
          onCancel: controller.cancelDownload,
        );
      }

      // 默认下载按钮（如果有图片显示两个按钮）
      final hasImages = controller.videoInfo.value?.images.isNotEmpty ?? false;
      return hasImages
          ? _DownloadButtons(
              onDownloadVideo: controller.downloadVideo,
              onDownloadImages: controller.downloadImages,
            )
          : _DownloadButton(onDownload: controller.downloadVideo);
    });
  }
}

/// 图片下载中组件
class _ImageDownloadingWidget extends StatelessWidget {
  final double progress;
  final int currentIndex;
  final int total;
  final VoidCallback onCancel;

  const _ImageDownloadingWidget({
    required this.progress,
    required this.currentIndex,
    required this.total,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.pink.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '正在下载图片...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$currentIndex / $total',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_rounded, color: Colors.white),
            label: const Text(
              '取消下载',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 下载完成组件（带图片下载）
class _DownloadCompletedWithImages extends StatelessWidget {
  final File file;
  final bool hasImages;
  final bool imagesDownloaded;
  final VoidCallback onDownloadImages;
  final VoidCallback onReset;

  const _DownloadCompletedWithImages({
    required this.file,
    required this.hasImages,
    required this.imagesDownloaded,
    required this.onDownloadImages,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.teal.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '视频下载完成！',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      imagesDownloaded ? '所有内容已下载完成' : '视频已保存到本地',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 18, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        file.path,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 20,
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: file.path));
                        Get.snackbar(
                          '已复制',
                          '文件路径已复制到剪贴板',
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      },
                      tooltip: '复制路径',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 如果有图片且未下载，显示下载图片按钮
          if (hasImages && !imagesDownloaded)
            ElevatedButton.icon(
              onPressed: onDownloadImages,
              icon: const Icon(Icons.photo_library_rounded, size: 20),
              label: const Text('下载图片'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.25),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          if (hasImages && !imagesDownloaded) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('重新下载'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (await file.exists()) {
                      final fileSize = await file.length();
                      Get.snackbar(
                        '文件信息',
                        '文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.white.withOpacity(0.95),
                        colorText: Colors.black87,
                      );
                    } else {
                      Get.snackbar(
                        '提示',
                        '文件不存在，可能已被删除',
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.orange.withOpacity(0.9),
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  label: const Text('查看信息'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 下载中组件
class _DownloadingWidget extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;

  const _DownloadingWidget({
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '下载中...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_rounded, color: Colors.white),
            label: const Text(
              '取消下载',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 双下载按钮组件
class _DownloadButtons extends StatelessWidget {
  final VoidCallback onDownloadVideo;
  final VoidCallback onDownloadImages;

  const _DownloadButtons({
    required this.onDownloadVideo,
    required this.onDownloadImages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DownloadButton(
            onDownload: onDownloadVideo,
            label: '下载视频',
            icon: Icons.video_library_rounded,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF009688),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DownloadButton(
            onDownload: onDownloadImages,
            label: '下载图片',
            icon: Icons.photo_library_rounded,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0),
                Color(0xFFE91E63),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 下载按钮组件
class _DownloadButton extends StatelessWidget {
  final VoidCallback onDownload;
  final String label;
  final IconData icon;
  final Gradient? gradient;

  const _DownloadButton({
    required this.onDownload,
    this.label = '下载视频',
    this.icon = Icons.download_rounded,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = gradient ?? const LinearGradient(
      colors: [
        Color(0xFF4CAF50),
        Color(0xFF009688),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: defaultGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient?.colors.first ?? const Color(0xFF4CAF50)).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDownload,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
