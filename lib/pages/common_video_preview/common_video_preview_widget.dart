import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../../../controllers/video_recording_controller.dart';
import 'package:calculator_app/widgets/app_background.dart';
import 'tiktok_progress_bar_painter.dart';
import 'common_video_preview_controller.dart';

class CommonVideoPreviewWidget extends StatefulWidget {
  final Widget? child;

  const CommonVideoPreviewWidget({Key? key, this.child}) : super(key: key);

  @override
  State<CommonVideoPreviewWidget> createState() => _CommonVideoPreviewWidgetState();
}

class _CommonVideoPreviewWidgetState extends State<CommonVideoPreviewWidget> {
  late final CommonVideoPreviewController controller;
  double _dragStartX = 0.0;
  double _currentDragX = 0.0;
  final double _dragThreshold = 100.0;

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
      backgroundColor: Colors.black,
      body: Obx(() {
        // 全屏模式
        if (controller.isFullScreen.value) {
          return _buildFullScreenPlayer();
        }

        // 自定义 child 模式
        if (widget.child != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: widget.child!,
          );
        }

        // 正常模式
        return Scaffold(
          backgroundColor: Colors.black,
          body: AppBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _buildVideoPlayer(),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 构建视频播放器（使用 PageView）
  Widget _buildVideoPlayer() {
    return Obx(() {
      // 如果视频列表为空
      if (controller.videos.isEmpty) {
        return const Center(
          child: Text(
            '没有视频',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      }

      return GestureDetector(
        // 水平拖动手势用于翻页
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          _currentDragX = details.globalPosition.dx;
        },
        onHorizontalDragEnd: (details) {
          final dragDistance = _currentDragX - _dragStartX;

          // 只有在拖动距离超过阈值且没有缩放时才翻页
          final scale = controller.transformationController.value.getMaxScaleOnAxis();
          if (dragDistance.abs() > _dragThreshold && scale == 1.0) {
            if (dragDistance > 0 && controller.canGoPrevious) {
              controller.pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else if (dragDistance < 0 && controller.canGoNext) {
              controller.pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        child: PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          physics: const NeverScrollableScrollPhysics(), // 禁用默认滑动
          itemCount: controller.videos.length,
          itemBuilder: (context, index) {
            return _buildVideoPage(index);
          },
        ),
      );
    });
  }

  /// 构建单个视频页面
  Widget _buildVideoPage(int index) {
    return Obx(() {
      // 只显示当前索引页面的视频，其他页面显示黑色背景
      if (index != controller.currentIndex.value) {
        return Container(color: Colors.black);
      }

      // 显示加载或错误状态
      if (controller.hasError.value) {
        return Container(
          color: Colors.black,
          child: Center(child: _buildErrorView()),
        );
      }

      if (!controller.isInitialized.value) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      }

      final videoController = controller.controller.value;
      if (videoController == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      }

      return Stack(
        children: [
          // 视频播放器 - 支持缩放
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: controller.togglePlayPause,
              onTap: () {
                controller.showControls.value = !controller.showControls.value;
              },
              child: InteractiveViewer(
                transformationController: controller.transformationController,
                minScale: 1.0,
                maxScale: 3.0,
                constrained: true,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: videoController.value.aspectRatio,
                    child: VideoPlayer(videoController),
                  ),
                ),
              ),
            ),
          ),

          // 底部控制栏
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
      );
    });
  }

  /// 构建全屏播放器
  Widget _buildFullScreenPlayer() {
    return Obx(() {
      final videoController = controller.controller.value;
      if (videoController == null) return const SizedBox.shrink();

      return Stack(
        children: [
          // 视频播放器
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                _dragStartX = details.globalPosition.dx;
              },
              onHorizontalDragUpdate: (details) {
                _currentDragX = details.globalPosition.dx;
              },
              onHorizontalDragEnd: (details) {
                final dragDistance = _currentDragX - _dragStartX;
                final scale = controller.transformationController.value.getMaxScaleOnAxis();
                if (dragDistance.abs() > _dragThreshold && scale == 1.0) {
                  if (dragDistance > 0 && controller.canGoPrevious) {
                    controller.pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else if (dragDistance < 0 && controller.canGoNext) {
                    controller.pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
              onDoubleTap: controller.togglePlayPause,
              onTap: () {
                controller.showControls.value = !controller.showControls.value;
              },
              child: InteractiveViewer(
                transformationController: controller.transformationController,
                minScale: 1.0,
                maxScale: 3.0,
                constrained: true,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: videoController.value.aspectRatio,
                    child: VideoPlayer(videoController),
                  ),
                ),
              ),
            ),
          ),

          // 顶部控制栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: (!controller.isPlaying || controller.showControls.value) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: controller.toggleFullScreen,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        controller.videoTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 页码指示
                    if (controller.videos.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.currentIndex.value + 1}/${controller.videos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: controller.toggleFullScreen,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部控制栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: (!controller.isPlaying || controller.showControls.value) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: _buildTikTokStyleProgressBar(),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// 构建 AppBar
  Widget _buildAppBar() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  Text(
                    controller.videoSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
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
              icon: Icon(
                controller.isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: controller.toggleFullScreen,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
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

  /// 构建错误视图
  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '视频加载失败',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '文件不存在或已被删除',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        if (controller.videos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              '滑动查看其他视频',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建抖音风格进度条
  Widget _buildTikTokStyleProgressBar() {
    return Obx(() {
      final position = controller.currentPosition;
      final duration = controller.totalDuration;
      final buffer = controller.bufferedPosition;

      return Column(
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
                },
                onHorizontalDragUpdate: (details) {
                  controller.updateScrubbing(details.globalPosition);
                },
                onHorizontalDragEnd: (details) {
                  controller.endScrubbing();
                },
                onTapDown: (details) {
                  controller.startScrubbing(details.globalPosition);
                },
                onTapUp: (details) {
                  controller.endScrubbing();
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
