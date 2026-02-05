import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/video_downloaded_controller.dart';
import '../models/downloaded_video_model.dart';
import 'package:calculator_app/widgets/app_background.dart';
import 'widgets/video_card.dart';
import 'widgets/video_details_dialog.dart';

/// 视频已下载页面
class VideoDownloadedPage extends GetView<VideoDownloadedController> {
  const VideoDownloadedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          // 判断是否为空
          final isEmpty = controller.displayedVideos.isEmpty;

          return FadeTransition(
            opacity: controller.fadeAnimation,
            child: SlideTransition(
              position: controller.slideAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAppBar(),
                  Expanded(
                    child: isEmpty ? _buildEmptyView() : _buildVideoList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建自定义AppBar
  Widget _buildAppBar() {
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
          Expanded(
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: '搜索已下载的视频',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon: Obx(() {
                  if (!controller.isSearching.value) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      controller.searchController.clear();
                    },
                  );
                }),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 100,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            controller.isSearching.value ? '未找到匹配的视频' : '还没有下载视频',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.isSearching.value
                ? '试试其他关键词'
                : '去下载页面添加一些视频吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视频列表
  Widget _buildVideoList() {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: controller.displayedVideos.length,
        // 优化：添加缓存范围，减少重建
        cacheExtent: 500,
        itemBuilder: (context, index) {
          final video = controller.displayedVideos[index];
          return VideoCard(
            key: ValueKey(video.id),
            video: video,
            index: index,
            onPreview: (v, i) => _previewVideo(v, i),
            onShare: (v) => _shareVideo(v),
            onMenu: (action, v, i) => _handleVideoMenu(action, v, i),
          );
        },
      ),
    );
  }

  /// 处理视频菜单
  void _handleVideoMenu(String action, DownloadedVideoModel video, int index) {
    switch (action) {
      case 'preview':
        _previewVideo(video, index);
        break;
      case 'info':
        Get.dialog(VideoDetailsDialog(video: video));
        break;
      case 'delete':
        _showDeleteDialog(video);
        break;
    }
  }

  /// 预览视频
  void _previewVideo(DownloadedVideoModel video, int index) {
    Get.toNamed('/video-preview', arguments: {
      'videos': controller.displayedVideos,
      'index': index,
    });
  }

  /// 分享视频
  Future<void> _shareVideo(DownloadedVideoModel video) async {
    try {
      await Share.shareXFiles(
        [XFile(video.localPath)],
        text: '分享视频: ${video.title}',
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
  void _showDeleteDialog(DownloadedVideoModel video) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('确认删除'),
        content: Text('确定要删除视频 "${video.title}" 吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteVideo(video.id);
              Get.back();
              Get.snackbar(
                '成功',
                '视频已删除',
                backgroundColor: Colors.green.withOpacity(0.9),
                colorText: Colors.white,
              );
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
