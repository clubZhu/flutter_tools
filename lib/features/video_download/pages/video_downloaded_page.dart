import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../services/download_history_service.dart';
import '../models/downloaded_video_model.dart';

/// 视频已下载页面
class VideoDownloadedPage extends StatefulWidget {
  const VideoDownloadedPage({super.key});

  @override
  State<VideoDownloadedPage> createState() => _VideoDownloadedPageState();
}

class _VideoDownloadedPageState extends State<VideoDownloadedPage> {
  final DownloadHistoryService _historyService = DownloadHistoryService();
  final TextEditingController _searchController = TextEditingController();
  List<DownloadedVideoModel> _displayedVideos = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initData() async {
    await _historyService.init();
    setState(() {
      _displayedVideos = _historyService.videos;
    });
  }

  /// 搜索监听
  void _onSearch() {
    final keyword = _searchController.text;
    setState(() {
      if (keyword.isEmpty) {
        _displayedVideos = _historyService.videos;
        _isSearching = false;
      } else {
        _displayedVideos = _historyService.searchVideos(keyword);
        _isSearching = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('已下载'),
        centerTitle: true,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _historyService.refresh();
              setState(() {
                _displayedVideos = _historyService.videos;
              });
              Get.snackbar(
                '已刷新',
                '已扫描下载目录',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
            tooltip: '刷新列表',
          ),
          // 搜索按钮
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _searchController.clear();
              } else {
                _showSearchDialog();
              }
            },
          ),
          // 选择按钮
          IconButton(
            icon: const Icon(Icons.check_box),
            onPressed: () => _showSelectionMode(),
          ),
          // 更多菜单
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('按时间排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_size',
                child: Row(
                  children: [
                    Icon(Icons.storage, size: 20),
                    SizedBox(width: 8),
                    Text('按大小排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('清空记录', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 构建页面主体
  Widget _buildBody() {
    if (_displayedVideos.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        // 统计信息
        _buildStatsBar(),
        // 视频列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _displayedVideos.length,
            itemBuilder: (context, index) {
              final video = _displayedVideos[index];
              return _buildVideoCard(video);
            },
          ),
        ),
      ],
    );
  }

  /// 构建统计栏
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.video_library,
            label: '视频',
            value: '${_historyService.length}',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.blue.shade200,
          ),
          _buildStatItem(
            icon: Icons.storage,
            label: '总大小',
            value: _historyService.getTotalSizeFormatted(),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
          ),
        ),
      ],
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有下载的视频',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去视频下载页面下载一些视频吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视频卡片
  Widget _buildVideoCard(DownloadedVideoModel video) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _previewVideo(video),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 视频标题和平台
              Row(
                children: [
                  _buildPlatformIcon(video.platform),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${video.author} · ${video.downloadedAtFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 更多操作
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleVideoMenu(value, video),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 20),
                            SizedBox(width: 8),
                            Text('预览'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text('分享'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 8),
                            Text('详情'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: '时长',
                    value: video.durationFormatted,
                  ),
                  _buildInfoChip(
                    icon: Icons.storage,
                    label: '大小',
                    value: video.fileSizeFormatted,
                  ),
                  _buildInfoChip(
                    icon: Icons.folder,
                    label: '位置',
                    value: video.localPath,
                    isPath: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _previewVideo(video),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('预览'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showInfoDialog(video),
                    child: const Icon(Icons.info_outline),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _confirmDelete(video),
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

  /// 构建平台图标
  Widget _buildPlatformIcon(String platform) {
    IconData icon;
    Color color;

    switch (platform) {
      case 'douyin':
        icon = Icons.music_note;
        color = Colors.black;
        break;
      case 'tiktok':
        icon = Icons.music_video;
        color = const Color(0xFF00F2EA);
        break;
      case 'youtube':
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case 'bilibili':
        icon = Icons.tv;
        color = const Color(0xFF00A1D6);
        break;
      default:
        icon = Icons.video_library;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    bool isPath = false,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200), // 限制最大宽度
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 减少padding
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700), // 减小图标
          const SizedBox(width: 3),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11, // 减小字体
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              isPath ? value.split('/').last : value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 预览视频
  void _previewVideo(DownloadedVideoModel video) {
    Get.to(
      () => _VideoPreviewPage(video: video),
      transition: Transition.fadeIn,
    );
  }

  /// 显示信息对话框
  void _showInfoDialog(DownloadedVideoModel video) {
    Get.dialog(
      AlertDialog(
        title: const Text('视频详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('标题', video.title),
              _detailRow('作者', video.author),
              _detailRow('平台', video.platformName),
              _detailRow('时长', video.durationFormatted),
              _detailRow('大小', video.fileSizeFormatted),
              _detailRow('下载时间', video.downloadedAtFormatted),
              _detailRow('本地路径', video.localPath, isPath: true),
              if (video.description.isNotEmpty)
                _detailRow('描述', video.description, maxLines: 3),
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

  /// 详情行
  Widget _detailRow(String label, String value, {bool isPath = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: isPath
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 显示完整路径（可选择）
                      SelectableText(
                        value,
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontSize: 12,
                        ),
                        // 不限制行数，完整显示
                      ),
                      // 添加复制按钮
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          Get.snackbar(
                            '已复制',
                            '路径已复制到剪贴板',
                            duration: const Duration(seconds: 1),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '复制',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: TextStyle(color: Colors.grey.shade900),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  /// 确认删除
  void _confirmDelete(DownloadedVideoModel video) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${video.title}" 吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.deleteVideo(video.id);
              Get.back(); // 关闭对话框
              setState(() {
                _displayedVideos = _historyService.videos;
              });
              Get.snackbar(
                '已删除',
                '视频已从下载记录中移除',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('搜索视频'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入标题、作者或描述',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Get.back();
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示选择模式
  void _showSelectionMode() {
    Get.snackbar(
      '提示',
      '批量删除功能开发中',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 处理视频菜单操作
  void _handleVideoMenu(String action, DownloadedVideoModel video) {
    switch (action) {
      case 'preview':
        _previewVideo(video);
        break;
      case 'share':
        Get.snackbar('提示', '分享功能开发中', snackPosition: SnackPosition.BOTTOM);
        break;
      case 'info':
        _showInfoDialog(video);
        break;
      case 'delete':
        _confirmDelete(video);
        break;
    }
  }

  /// 处理主菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort_date':
        setState(() {
          _displayedVideos.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
        });
        Get.snackbar('已排序', '按下载时间排序', snackPosition: SnackPosition.BOTTOM);
        break;
      case 'sort_size':
        setState(() {
          _displayedVideos.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        });
        Get.snackbar('已排序', '按文件大小排序', snackPosition: SnackPosition.BOTTOM);
        break;
      case 'clear_all':
        _confirmClearAll();
        break;
    }
  }

  /// 确认清空所有
  void _confirmClearAll() {
    Get.dialog(
      AlertDialog(
        title: const Text('确认清空'),
        content: Text('确定要清空所有 ${_historyService.length} 个下载记录吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.clearAll();
              Get.back();
              setState(() {
                _displayedVideos = [];
              });
              Get.snackbar(
                '已清空',
                '所有下载记录已清空',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

/// 视频预览页面
class _VideoPreviewPage extends StatefulWidget {
  final DownloadedVideoModel video;

  const _VideoPreviewPage({required this.video});

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.video.localPath);
      if (await file.exists()) {
        _controller = VideoPlayerController.file(file);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      print('视频初始化失败: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.video.title),
        centerTitle: true,
      ),
      body: Center(
        child: _hasError
            ? _buildErrorView()
            : !_isInitialized
                ? const CircularProgressIndicator()
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        const Text('视频加载失败'),
        const SizedBox(height: 8),
        Text(
          '文件不存在: ${widget.video.localPath}',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Container(
        color: Colors.black26,
        child: Center(
          child: Icon(
            _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 64,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
