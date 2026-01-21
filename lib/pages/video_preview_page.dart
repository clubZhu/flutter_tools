import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/video_recording_controller.dart';
import '../models/video_recording_model.dart';

/// 视频预览页面
class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({Key? key}) : super(key: key);

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _videoController;
  final VideoRecordingModel _video = Get.arguments as VideoRecordingModel;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  /// 初始化视频播放器
  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(File(_video.filePath));
      await _videoController.initialize();
      setState(() {
        _isInitialized = true;
      });

      // 监听播放状态
      _videoController.addListener(() {
        if (_videoController.value.isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = _videoController.value.isPlaying;
          });
        }
      });
    } catch (e) {
      print('初始化视频播放器失败: $e');
      Get.snackbar('错误', '视频加载失败: $e');
    }
  }

  /// 切换播放/暂停
  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
    });
  }

  /// 分享视频
  void _shareVideo() async {
    try {
      await Share.shareXFiles(
        [XFile(_video.filePath)],
        text: '分享我的录制视频',
      );
    } catch (e) {
      Get.snackbar('错误', '分享失败: $e');
    }
  }

  /// 处理删除视频
  Future<void> _handleDelete() async {
    // 显示确认对话框
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '确认删除',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要删除这个视频吗？\n此操作无法撤销。',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 获取控制器
        final controller = Get.find<VideoRecordingController>();
        
        // 删除视频
        await controller.deleteVideo(_video.id);
        
        // 关闭预览页面
        if (mounted) {
          Get.back();
        }
      } catch (e) {
        Get.snackbar(
          '错误',
          '删除视频失败: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('视频预览'),
        centerTitle: true,
        actions: [
          // 分享按钮
          IconButton(
            onPressed: _shareVideo,
            icon: const Icon(Icons.share),
            tooltip: '分享',
          ),
        ],
      ),
      body: Column(
        children: [
          // 视频播放器
          Expanded(
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: Stack(
                        children: [
                          VideoPlayer(_videoController),
                          // 播放/暂停按钮
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: _isPlaying ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(
                      color: Colors.white,
                    ),
            ),
          ),

          // 视频信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 视频名称
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _video.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showRenameDialog(),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      tooltip: '重命名',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 视频详细信息
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.schedule,
                      label: _video.durationFormatted,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.storage,
                      label: _video.fileSizeFormatted,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _video.createdAtFormatted,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 控制按钮
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text('删除'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('保留'),
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

  /// 构建信息标签
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 显示重命名对话框
  void _showRenameDialog() {
    final TextEditingController nameController =
        TextEditingController(text: _video.name);

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '重命名视频',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '请输入新的视频名称',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                try {
                  final controller = Get.find<VideoRecordingController>();
                  await controller.updateVideoName(
                    _video.id,
                    nameController.text,
                  );
                  Get.back();
                  setState(() {}); // 刷新UI
                  Get.snackbar(
                    '成功',
                    '视频名称已更新',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    '错误',
                    '更新视频名称失败: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
