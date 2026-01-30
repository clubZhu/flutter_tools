import 'dart:io';
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
                  return Column(
                    children: [
                      // 统计栏
                      _buildStatisticsBar(),
                      // 视频列表
                      Expanded(
                        child: _buildVideoList(),
                      ),
                    ],
                  );
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

  /// 构建统计栏
  Widget _buildStatisticsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatisticItem(
              icon: Icons.video_library,
              label: '总数量',
              value: '${controller.videoList.length}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatisticItem(
              icon: Icons.schedule,
              label: '总时长',
              value: _formatTotalDuration(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatisticItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 格式化总时长
  String _formatTotalDuration() {
    final totalSeconds = controller.videoList.fold<int>(
      0,
      (sum, video) => sum + video.duration,
    );

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else {
      return '$minutes分钟';
    }
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
        padding: const EdgeInsets.only(bottom: 16),
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
          // 封面区域 - 添加Hero标签
          Hero(
            tag: 'recording_cover_${video.id}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _previewVideo(video),
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
                      // 封面图
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: video.thumbnailPath.isNotEmpty
                            ? Image.file(
                                File(video.thumbnailPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultCover();
                                },
                              )
                            : _buildDefaultCover(),
                      ),
                      // 播放按钮覆盖层
                      Container(
                        color: Colors.black.withOpacity(0.2),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      // 时长标签
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.durationFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // 更多菜单
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton<String>(
                          onSelected: (value) => _handleMenuAction(value, video),
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
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('重命名'),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 信息区域
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  video.name,
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
                // 创建时间和文件大小
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      video.createdAtFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建默认封面
  Widget _buildDefaultCover() {
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

  /// 处理菜单操作
  void _handleMenuAction(String action, VideoRecordingModel video) {
    switch (action) {
      case 'preview':
        _previewVideo(video);
        break;
      case 'rename':
        _showRenameDialog(video);
        break;
      case 'delete':
        _showDeleteDialog(video);
        break;
    }
  }

  /// 预览视频
  void _previewVideo(VideoRecordingModel video) {
    Get.toNamed('/video-preview', arguments: video);
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
