import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:calculator_app/widgets/app_background.dart';
import '../../controllers/video_download_controller.dart';

/// 视频/图片预览区域
class VideoPreviewSection extends StatelessWidget {
  const VideoPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadController>();

    return Obx(() {
      final videoInfo = controller.videoInfo.value;
      if (videoInfo == null) return const SizedBox.shrink();

      // 判断是图文还是视频
      final isImagePost = videoInfo.images.isNotEmpty &&
          (videoInfo.videoUrl.isEmpty || !videoInfo.videoUrl.startsWith('http'));

      return AppGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isImagePost
                      ? Icons.photo_library_rounded
                      : Icons.play_circle_outline,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isImagePost ? '图文预览 (${videoInfo.images.length}张)' : '视频预览',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isImagePost)
              _ImageGridWidget(images: videoInfo.images)
            else
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
    });
  }
}

/// 图片网格预览组件
class _ImageGridWidget extends StatelessWidget {
  final List<dynamic> images;

  const _ImageGridWidget({required this.images});

  @override
  Widget build(BuildContext context) {
    // 根据图片数量决定布局
    if (images.length == 1) {
      return _SingleImageLayout(url: images[0].url);
    } else if (images.length == 2) {
      return _TwoImagesLayout(images: images);
    } else if (images.length <= 4) {
      return _FourImagesLayout(images: images);
    } else {
      return _NineImagesLayout(images: images);
    }
  }
}

/// 单图布局
class _SingleImageLayout extends StatelessWidget {
  final String url;

  const _SingleImageLayout({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: _NetworkImage(url: url),
      ),
    );
  }
}

/// 两图布局
class _TwoImagesLayout extends StatelessWidget {
  final List<dynamic> images;

  const _TwoImagesLayout({required this.images});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: Row(
          children: [
            Expanded(
              child: _NetworkImage(url: images[0].url),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _NetworkImage(url: images[1].url),
            ),
          ],
        ),
      ),
    );
  }
}

/// 四图布局
class _FourImagesLayout extends StatelessWidget {
  final List<dynamic> images;

  const _FourImagesLayout({required this.images});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _NetworkImage(url: images[0].url),
                  ),
                  const SizedBox(width: 4),
                  if (images.length > 1)
                    Expanded(
                      child: _NetworkImage(url: images[1].url),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _NetworkImage(url: images.length > 2 ? images[2].url : ''),
                  ),
                  const SizedBox(width: 4),
                  if (images.length > 3)
                    Expanded(
                      child: _NetworkImage(url: images[3].url),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 九图布局
class _NineImagesLayout extends StatelessWidget {
  final List<dynamic> images;

  const _NineImagesLayout({required this.images});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 350,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: images.length > 9 ? 9 : images.length,
          itemBuilder: (context, index) {
            final isMore = index == 8 && images.length > 9;
            return _NetworkImage(
              url: images[index].url,
              showMoreBadge: isMore,
              moreCount: images.length - 9,
            );
          },
        ),
      ),
    );
  }
}

/// 网络图片组件
class _NetworkImage extends StatelessWidget {
  final String url;
  final bool showMoreBadge;
  final int moreCount;

  const _NetworkImage({
    required this.url,
    this.showMoreBadge = false,
    this.moreCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade800,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade800,
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            );
          },
        ),
        if (showMoreBadge)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Text(
                '+$moreCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
