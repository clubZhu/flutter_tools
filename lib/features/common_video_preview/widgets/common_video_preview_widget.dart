import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import 'package:calculator_app/features/video_recording/controllers/video_recording_controller.dart';
import 'package:calculator_app/widgets/app_background.dart';
import 'tiktok_progress_bar_painter.dart';
import '../controllers/common_video_preview_controller.dart';

class CommonVideoPreviewWidget extends StatefulWidget {
  final Widget? child;

  const CommonVideoPreviewWidget({Key? key, this.child}) : super(key: key);

  @override
  State<CommonVideoPreviewWidget> createState() => _CommonVideoPreviewWidgetState();
}

class _CommonVideoPreviewWidgetState extends State<CommonVideoPreviewWidget> {
  late final CommonVideoPreviewController controller;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CommonVideoPreviewController());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // 自定义 child 模式
        if (widget.child != null) {
          return Scaffold(
            body: widget.child!,
          );
        }

        // 正常模式 - iOS 相册风格
        return Scaffold(
          body: AppBackground(
            child: Column(
              children: [
                const SizedBox(height: 30,),
                _buildAppBar(),
                Expanded(
                  child: _buildiOSStyleGallery(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 构建 iOS 相册风格视频列表
  Widget _buildiOSStyleGallery() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _currentPage = controller.pageController.page ?? controller.currentIndex.value.toDouble();
          });
        }
        return false;
      },
      child: PageView.builder(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        itemCount: controller.videos.length,
        itemBuilder: (context, index) {
          return _buildiOSVideoPage(index);
        },
      ),
    );
  }

  /// 构建 iOS 风格视频页面
  Widget _buildiOSVideoPage(int index) {
    return Obx(() {
      if (!controller.isControllersReady) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      }

      final videoController = controller.getVideoController(index);
      final isCurrentPage = index == controller.currentIndex.value;

      return _buildVideoContent(index, videoController, isCurrentPage);
    });
  }

  /// 构建视频内容
  Widget _buildVideoContent(int index, VideoPlayerController? videoController, bool isCurrentPage) {
    if (videoController == null || !videoController.value.isInitialized) {
      return const SizedBox.expand();
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频播放器
          GestureDetector(
            onTap: isCurrentPage ? controller.togglePlayPause : null,
            onDoubleTap: isCurrentPage
                ? () {
                    controller.showControls.value = !controller.showControls.value;
                    // 切换进度条显示/隐藏
                    if (controller.showProgressBar.value) {
                      controller.hideProgressBar();
                    } else {
                      controller.showProgressBarOverlay();
                    }
                  }
                : null,
            child: Center(
              child: AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width / videoController.value.aspectRatio,
                      child: VideoPlayer(videoController),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 播放/暂停按钮（居中显示）
          if (isCurrentPage)
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: videoController,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: !value.isPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: controller.togglePlayPause,
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 底部控制栏（只显示在当前页面）
          if (isCurrentPage)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: (!controller.isPlaying || controller.showControls.value) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _buildTikTokStyleProgressBar(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建 AppBar
  Widget _buildAppBar() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16,8),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.videoTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.videoSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 页码指示
            if (controller.videos.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${controller.currentIndex.value + 1}/${controller.videos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareVideo(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _showDeleteDialog(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建抖音风格进度条
  Widget _buildTikTokStyleProgressBar() {
    return Obx(() {
      final position = controller.currentPosition;
      final duration = controller.totalDuration;
      final buffer = controller.bufferedPosition;

      return AnimatedOpacity(
        opacity: controller.showProgressBar.value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: controller.showProgressBar.value
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        // 时间预览（拖动时显示）
                        if (controller.isScrubbing.value)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.formatDuration(Duration(milliseconds: position.toInt())),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // 进度条
                        GestureDetector(
                          onHorizontalDragStart: (details) {
                            controller.startScrubbing(details.globalPosition);
                            controller.showProgressBarOverlay();
                          },
                          onHorizontalDragUpdate: (details) {
                            controller.updateScrubbing(details.globalPosition);
                            controller.resetProgressBarTimer();
                          },
                          onHorizontalDragEnd: (details) {
                            controller.endScrubbing();
                            controller.showProgressBarOverlay();
                          },
                          onTapDown: (details) {
                            controller.startScrubbing(details.globalPosition);
                            controller.showProgressBarOverlay();
                          },
                          onTapUp: (details) {
                            controller.endScrubbing();
                            controller.showProgressBarOverlay();
                          },
                          child: Container(
                            key: controller.progressBarKey,
                            height: 24,
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.1),
                            child: CustomPaint(
                              painter: TikTokProgressBarPainter(
                                position: position,
                                duration: duration,
                                buffer: buffer,
                                isScrubbing: controller.isScrubbing.value,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.formatDuration(Duration(milliseconds: position.toInt())),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            controller.formatDuration(controller.duration),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }

  /// 分享视频
  Future<void> _shareVideo() async {
    try {
      await Share.shareXFiles(
        [XFile(controller.videoPath)],
        text: '分享视频',
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '分享失败: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  /// 显示删除确认对话框
  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('确认删除'),
        content: Text('确定要删除视频 "${controller.videoTitle}" 吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final videoController = Get.find<VideoRecordingController>();
                await videoController.deleteVideo(controller.videoId);
                Get.back();
                Get.back();
                Get.snackbar(
                  '成功',
                  '视频已删除',
                  backgroundColor: Colors.green.withOpacity(0.9),
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar(
                  '错误',
                  '删除视频失败: $e',
                  backgroundColor: Colors.red.withOpacity(0.9),
                  colorText: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
