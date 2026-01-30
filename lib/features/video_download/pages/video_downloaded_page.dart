import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../services/download_history_service.dart';
import '../models/downloaded_video_model.dart';
import 'package:calculator_app/widgets/app_background.dart';

/// 视频已下载页面
class VideoDownloadedPage extends StatefulWidget {
  const VideoDownloadedPage({super.key});

  @override
  State<VideoDownloadedPage> createState() => _VideoDownloadedPageState();
}

class _VideoDownloadedPageState extends State<VideoDownloadedPage>
    with TickerProviderStateMixin {
  final DownloadHistoryService _historyService = DownloadHistoryService();
  final TextEditingController _searchController = TextEditingController();
  List<DownloadedVideoModel> _displayedVideos = [];
  bool _isSearching = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initData();
    _searchController.addListener(_onSearch);
  }

  /// 初始化动画
  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
      body: AppBackground(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // 自定义 AppBar
                const SizedBox(height: 20,),
                _buildAppBar(),

                // 内容区域
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建自定义AppBar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              '已下载',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // 刷新按钮
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            // 搜索按钮
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
              onPressed: () {
                if (_isSearching) {
                  _searchController.clear();
                } else {
                  _showSearchDialog();
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            // 更多菜单
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.9)),
              color: Colors.white.withOpacity(0.95),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.video_library_rounded,
            label: '视频数量',
            value: '${_historyService.length}',
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildStatItem(
            icon: Icons.storage_rounded,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.download_done_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '还没有下载的视频',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '去视频下载页面下载一些视频吧',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('返回下载页面'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.25),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视频卡片
  Widget _buildVideoCard(DownloadedVideoModel video) {
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
            tag: 'video_cover_${video.id}',
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
                        child: video.coverUrl.isNotEmpty
                            ? Image.network(
                                video.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultCover();
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  );
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
                      if (video.duration != null)
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
                      // 平台标签
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildPlatformChip(video.platform),
                      ),
                      // 更多菜单
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton<String>(
                          onSelected: (value) => _handleVideoMenu(value, video),
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
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
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
                    _buildActionButton(
                      onPressed: () => _shareVideo(video),
                      icon: Icons.share,
                      label: '分享',
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

  /// 构建平台标签
  Widget _buildPlatformChip(String platform) {
    String displayName;
    switch (platform) {
      case 'douyin':
        displayName = '抖音';
        break;
      case 'tiktok':
        displayName = 'TikTok';
        break;
      case 'youtube':
        displayName = 'YouTube';
        break;
      case 'bilibili':
        displayName = 'B站';
        break;
      default:
        displayName = '视频';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayName,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
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

  /// 分享视频
  Future<void> _shareVideo(DownloadedVideoModel video) async {
    try {
      await Share.shareXFiles(
        [XFile(video.localPath)],
        text: '分享我的录制视频',
      );
    } catch (e) {
      Get.snackbar('错误', '分享失败: $e');
    }
  }

  /// 显示信息对话框
  void _showInfoDialog(DownloadedVideoModel video) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.cyan.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '视频详情',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '关闭',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.orange.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '确认删除',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要删除以下视频吗？',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                video.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '此操作无法撤销。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
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
                backgroundColor: Colors.green.withOpacity(0.9),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '删除',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.pink.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '搜索视频',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标题、作者或描述',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Get.back();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.orange.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '确认清空',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要清空所有下载记录吗？',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade50,
                    Colors.orange.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '共 ${_historyService.length} 个视频',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '此操作无法撤销。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
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
                backgroundColor: Colors.green.withOpacity(0.9),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '清空',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  bool _showControls = false;

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

        // 添加监听器
        _controller!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          // 自动播放
          _controller!.play();
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
    _controller?.removeListener(() {});
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 自定义AppBar
              _buildAppBar(),

              // 视频播放区域
              Expanded(
                child: Hero(
                  tag: 'video_cover_${widget.video.id}',
                  child: _hasError
                      ? _buildErrorView()
                      : !_isInitialized
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _buildVideoPlayer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.video.author,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.video.videoUrl));
              Get.snackbar(
                '已复制',
                '视频链接已复制到剪贴板',
                backgroundColor: Colors.green.withOpacity(0.9),
                colorText: Colors.white,
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
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
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频播放器
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // 底部控制栏和进度条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 进度条
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.blue,
                        bufferedColor: Colors.white.withOpacity(0.3),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 控制按钮行
                    Row(
                      children: [
                        // 播放/暂停按钮
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_controller!.value.isPlaying) {
                                _controller!.pause();
                              } else {
                                _controller!.play();
                              }
                            });
                          },
                          child: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 时间显示
                        Expanded(
                          child: Text(
                            '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 暂停指示器（仅在暂停且不显示控制栏时显示）
          if (!_controller!.value.isPlaying && !_showControls)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
