import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_recording_controller.dart';
import '../models/video_recording_model.dart';
import 'package:calculator_app/widgets/app_background.dart';

/// 视频历史列表页面
class VideoHistoryPage extends GetView<VideoRecordingController> {
  const VideoHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            const SizedBox(height: 20,),
            // 自定义 AppBar
            _buildAppBar(),

            // 内容区域
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Obx(() {
                  if (controller.videoList.isEmpty) {
                    return _buildEmptyView();
                  }
                  return _buildVideoList();
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/video-recording'),
        backgroundColor: Colors.red,
        child: const Icon(Icons.videocam, color: Colors.white),
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
            const Text(
              '录制历史',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // 刷新按钮
            IconButton(
              onPressed: controller.refreshVideoList,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: '刷新',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
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
            Icons.videocam_off,
            size: 100,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有录制的视频',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始录制',
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
      onRefresh: controller.refreshVideoList,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controller.videoList.length,
        itemBuilder: (context, index) {
          final video = controller.videoList[index];
          return _buildVideoCard(video);
        },
      ),
    );
  }

  /// 构建视频卡片
  Widget _buildVideoCard(VideoRecordingModel video) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => Get.toNamed('/video-preview', arguments: video),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频名称
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.createdAtFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // 更多操作按钮
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, video),
                  icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.9)),
                  color: Colors.white.withOpacity(0.95),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('重命名'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 视频信息
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.schedule,
                  label: '时长',
                  value: video.durationFormatted,
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  icon: Icons.storage,
                  label: '大小',
                  value: video.fileSizeFormatted,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Get.toNamed('/video-preview', arguments: video),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRenameDialog(video),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('重命名'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showDeleteDialog(video),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(String action, VideoRecordingModel video) {
    switch (action) {
      case 'rename':
        _showRenameDialog(video);
        break;
      case 'delete':
        _showDeleteDialog(video);
        break;
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(VideoRecordingModel video) {
    final TextEditingController nameController =
        TextEditingController(text: video.name);

    Get.dialog(
      AlertDialog(
        title: const Text('重命名视频'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '请输入新的视频名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await controller.updateVideoName(
                  video.id,
                  nameController.text,
                );
                Get.back();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(VideoRecordingModel video) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除视频 "${video.name}" 吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteVideo(video.id);
              Get.back();
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
