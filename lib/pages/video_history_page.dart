import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_recording_controller.dart';
import '../models/video_recording_model.dart';
import 'video_recording_page.dart';

/// 视频历史列表页面
class VideoHistoryPage extends GetView<VideoRecordingController> {
  const VideoHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录制历史'),
        centerTitle: true,
        actions: [
          // 刷新按钮
          IconButton(
            onPressed: controller.refreshVideoList,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.videoList.isEmpty) {
          return _buildEmptyView();
        }
        return _buildVideoList();
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/video-recording'),
        backgroundColor: Colors.red,
        child: const Icon(Icons.videocam, color: Colors.white),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有录制的视频',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始录制',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => Get.toNamed('/video-preview', arguments: video),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 视频名称
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: Colors.red,
                    size: 32,
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
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.createdAtFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 更多操作按钮
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, video),
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
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('播放'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRenameDialog(video),
                      icon: const Icon(Icons.edit),
                      label: const Text('重命名'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showDeleteDialog(video),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Icon(Icons.delete),
                  ),
                ],
              ),
            ],
          ),
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
