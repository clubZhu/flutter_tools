import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/video_downloaded_controller.dart';
import '../models/downloaded_video_model.dart';
import 'package:calculator_app/widgets/app_background.dart';

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
          return _VideoCard(
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
        _showVideoDetails(video);
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

  /// 显示视频详情
  void _showVideoDetails(DownloadedVideoModel video) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('视频详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('标题', video.title),
              _buildDetailRow('作者', video.author),
              _buildDetailRow('平台', video.platformName),
              _buildDetailRow('时长', video.durationFormatted),
              _buildDetailRow('大小', video.fileSizeFormatted),
              _buildDetailRow('下载时间', video.downloadedAtFormatted),
              if (video.description.isNotEmpty)
                _buildDetailRow('描述', video.description),
              _buildDetailRow('视频链接', video.videoUrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

/// 优化的视频卡片组件 - 使用 AutomaticKeepAliveClientMixin 保持状态
class _VideoCard extends StatefulWidget {
  final DownloadedVideoModel video;
  final int index;
  final Function(DownloadedVideoModel, int) onPreview;
  final Function(DownloadedVideoModel) onShare;
  final Function(String, DownloadedVideoModel, int) onMenu;

  const _VideoCard({
    super.key,
    required this.video,
    required this.index,
    required this.onPreview,
    required this.onShare,
    required this.onMenu,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 封面区域
          Hero(
            tag: 'video_cover_${widget.video.id}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onPreview(widget.video, widget.index),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // 封面图 - 使用优化的缩略图加载
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _VideoThumbnail(video: widget.video),
                      ),

                      // 时长标签
                      if (widget.video.duration != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: _DurationLabel(duration: widget.video.durationFormatted),
                        ),

                      // 平台标签
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _PlatformChip(name: widget.video.platformName),
                      ),

                      // 更多菜单
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _MoreMenuButton(
                          onSelected: (action) => widget.onMenu(action, widget.video, widget.index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 信息区域
          _VideoInfo(
            video: widget.video,
            onShare: () => widget.onShare(widget.video),
          ),
        ],
      ),
    );
  }
}

/// 优化的视频缩略图组件
class _VideoThumbnail extends StatelessWidget {
  final DownloadedVideoModel video;

  const _VideoThumbnail({required this.video});

  @override
  Widget build(BuildContext context) {
    // 优先使用本地缩略图
    if (video.localThumbnailPath.isNotEmpty) {
      return Image.file(
        File(video.localThumbnailPath),
        fit: BoxFit.cover,
        gaplessPlayback: true, // 优化：减少闪烁
        errorBuilder: (context, error, stackTrace) {
          return _NetworkThumbnail(video: video);
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

    return _NetworkThumbnail(video: video);
  }
}

/// 网络缩略图组件
class _NetworkThumbnail extends StatelessWidget {
  final DownloadedVideoModel video;

  const _NetworkThumbnail({required this.video});

  @override
  Widget build(BuildContext context) {
    if (video.coverUrl.isNotEmpty) {
      return Image.network(
        video.coverUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return const _DefaultCover();
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

    return const _DefaultCover();
  }
}

/// 默认封面组件
class _DefaultCover extends StatelessWidget {
  const _DefaultCover();

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

/// 时长标签组件
class _DurationLabel extends StatelessWidget {
  final String duration;

  const _DurationLabel({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        duration,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 平台标签组件
class _PlatformChip extends StatelessWidget {
  final String name;

  const _PlatformChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 更多菜单按钮组件
class _MoreMenuButton extends StatelessWidget {
  final Function(String) onSelected;

  const _MoreMenuButton({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      icon: Icon(
        Icons.more_vert,
        color: Colors.white.withOpacity(0.9),
        size: 20,
      ),
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'preview',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 8),
              Text('预览'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 8),
              Text('详情'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 视频信息组件
class _VideoInfo extends StatelessWidget {
  final DownloadedVideoModel video;
  final VoidCallback onShare;

  const _VideoInfo({
    required this.video,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // 作者和时间
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  video.author,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                video.downloadedAtFormatted,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 文件大小和操作按钮
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                video.fileSizeFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              _ActionButton(onPressed: onShare),
            ],
          ),
        ],
      ),
    );
  }
}

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share, size: 14, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 4),
            const Text(
              '分享',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
