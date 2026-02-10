import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/video_downloaded_controller.dart';
import '../models/downloaded_video_model.dart';
import '../models/downloaded_image_model.dart';
import 'package:calculator_app/widgets/app_background.dart';
import 'widgets/video_card.dart';
import 'widgets/video_details_dialog.dart';
import 'image_preview_page.dart';

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

          return FadeTransition(
            opacity: controller.fadeAnimation,
            child: SlideTransition(
              position: controller.slideAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAppBar(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        _buildVideoList(),
                        _buildImageList(),
                      ],
                    ),
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
                hintText: controller.currentTab.value == 0 ? '搜索已下载的视频' : '搜索已下载的图片',
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

  /// 构建TabBar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(5),
      child: TabBar(
        controller: controller.tabController,
        indicator: const BoxDecoration(),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        tabs: [
          _GlassTab(
            index: 0,
            controller: controller.tabController,
            icon: Icons.play_circle_rounded,
            label: '视频',
            count: controller.displayedVideos.length,
          ),
          _GlassTab(
            index: 1,
            controller: controller.tabController,
            icon: Icons.photo_library_rounded,
            label: '图片',
            count: controller.displayedImages.length,
          ),
        ],
      ),
    );
  }

  /// 构建视频列表
  Widget _buildVideoList() {
    return Obx(() {
      final isEmpty = controller.displayedVideos.isEmpty;

      if (isEmpty) {
        return _buildEmptyView(forVideo: true);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: controller.displayedVideos.length,
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
    });
  }

  /// 构建图片列表
  Widget _buildImageList() {
    return Obx(() {
      final isEmpty = controller.displayedImages.isEmpty;

      if (isEmpty) {
        return _buildEmptyView(forVideo: false);
      }

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: controller.refreshData,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: controller.displayedImages.length,
              itemBuilder: (context, index) {
                final image = controller.displayedImages[index];
                return _ImageGridItem(
                  image: image,
                  index: index,
                  onTap: () => _handleImageTap(index),
                  onLongPress: () => controller.selectImageAndEnterMode(image.id),
                );
              },
            ),
          ),
          // 多选模式底部操作栏
          _buildSelectionBottomBar(),
        ],
      );
    });
  }

  /// 构建选择模式底部操作栏
  Widget _buildSelectionBottomBar() {
    return Obx(() {
      if (!controller.isSelectionMode.value) {
        return const SizedBox.shrink();
      }

      final selectedCount = controller.selectedImageIds.length;

      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // 取消选择
                TextButton.icon(
                  onPressed: controller.disableSelectionMode,
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('取消', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                // 选中数量
                Expanded(
                  child: Text(
                    '已选 $selectedCount 张',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 全选/取消全选
                TextButton.icon(
                  onPressed: selectedCount == controller.displayedImages.length
                      ? controller.deselectAllImages
                      : controller.selectAllImages,
                  icon: Icon(
                    selectedCount == controller.displayedImages.length
                        ? Icons.deselect
                        : Icons.select_all,
                    color: Colors.white,
                  ),
                  label: Text(
                    selectedCount == controller.displayedImages.length ? '取消全选' : '全选',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                // 分享按钮
                IconButton(
                  onPressed: selectedCount > 0 ? controller.shareSelectedImages : null,
                  icon: const Icon(Icons.share, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: selectedCount > 0
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                // 删除按钮
                IconButton(
                  onPressed: selectedCount > 0 ? _showBatchDeleteDialog : null,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: selectedCount > 0
                        ? Colors.red.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 处理图片点击
  void _handleImageTap(int index) {
    if (controller.isSelectionMode.value) {
      final image = controller.displayedImages[index];
      controller.toggleImageSelection(image.id);
    } else {
      _showImagePreview(index);
    }
  }

  /// 显示批量删除对话框
  void _showBatchDeleteDialog() {
    final count = controller.selectedImageIds.length;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 张图片吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.deleteSelectedImages();
              Get.snackbar(
                '成功',
                '已删除 $count 张图片',
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

  /// 构建空视图
  Widget _buildEmptyView({required bool forVideo}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            forVideo ? Icons.video_library_rounded : Icons.photo_library_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            controller.isSearching.value ? '未找到匹配的内容' : (forVideo ? '还没有下载视频' : '还没有下载图片'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.isSearching.value ? '试试其他关键词' : '去下载页面添加一些内容吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
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

  /// 显示图片预览
  void _showImagePreview(int initialIndex) {
    Get.to(
      () => ImagePreviewPage(
        images: controller.displayedImages,
        initialIndex: initialIndex,
        onDelete: (index) async {
          final image = controller.displayedImages[index];
          await controller.deleteImage(image.id);
          Get.back();
          Get.snackbar(
            '成功',
            '图片已删除',
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
          );
        },
      ),
      transition: Transition.fadeIn,
    );
  }

  /// 显示图片菜单
  void _showImageMenu(DownloadedImageModel image, int index) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.preview, color: Colors.white),
                title: const Text('预览', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  _showImagePreview(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text('分享', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Get.back();
                  try {
                    await Share.shareXFiles(
                      [XFile(image.localPath)],
                      text: '分享图片: ${image.videoTitle}',
                    );
                  } catch (e) {
                    Get.snackbar(
                      '错误',
                      '分享失败: $e',
                      backgroundColor: Colors.red.withOpacity(0.9),
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _showImageDeleteDialog(image);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示图片删除确认对话框
  void _showImageDeleteDialog(DownloadedImageModel image) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('确认删除'),
        content: Text('确定要删除这张图片吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteImage(image.id);
              Get.back();
              Get.snackbar(
                '成功',
                '图片已删除',
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

/// 图片网格项
class _ImageGridItem extends StatelessWidget {
  final DownloadedImageModel image;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ImageGridItem({
    required this.image,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadedController>();

    return Obx(() {
      final isSelected = controller.isImageSelected(image.id);
      final isSelectionMode = controller.isSelectionMode.value;

      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: isSelected
                ? Border.all(color: Colors.purple, width: 3)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 本地图片
                Image.file(
                  File(image.localPath),
                  fit: BoxFit.cover,
                  color: isSelected
                      ? Colors.white.withOpacity(0.5)
                      : null,
                  colorBlendMode: isSelected
                      ? BlendMode.srcOver
                      : null,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade800,
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                ),
                // 选中标记
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.purple
                            : Colors.white.withOpacity(0.7),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.transparent,
                      ),
                    ),
                  ),
                // 文件大小标签
                if (!isSelectionMode)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        image.fileSizeFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// 数量徽章组件
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 毛玻璃Tab组件
class _GlassTab extends StatefulWidget {
  final int index;
  final TabController controller;
  final IconData icon;
  final String label;
  final int count;

  const _GlassTab({
    required this.index,
    required this.controller,
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  State<_GlassTab> createState() => _GlassTabState();
}

class _GlassTabState extends State<_GlassTab> {
  @override
  Widget build(BuildContext context) {
    return Tab(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final isSelected = widget.controller.index == widget.index;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 19,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              // _CountBadge(count: widget.count),
            ],
          );
        },
      ),
    );
  }
}
