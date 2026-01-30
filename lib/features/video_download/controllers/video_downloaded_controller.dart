import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/download_history_service.dart';
import '../models/downloaded_video_model.dart';

/// 视频已下载页面控制器
class VideoDownloadedController extends GetxController
    with GetTickerProviderStateMixin {
  final DownloadHistoryService _historyService = DownloadHistoryService();
  final TextEditingController searchController = TextEditingController();

  // 响应式变量
  final RxList<DownloadedVideoModel> displayedVideos = <DownloadedVideoModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoading = true.obs;

  // 动画控制器
  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    initData();
    searchController.addListener(_onSearch);
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearch);
    searchController.dispose();
    fadeController.dispose();
    slideController.dispose();
    super.onClose();
  }

  /// 初始化动画
  void _initAnimations() {
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeInOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: slideController, curve: Curves.easeOut),
    );

    fadeController.forward();
    slideController.forward();
  }

  /// 初始化数据
  Future<void> initData() async {
    isLoading.value = true;
    await _historyService.init();
    displayedVideos.value = _historyService.videos;
    isLoading.value = false;
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _historyService.refresh();
    displayedVideos.value = _historyService.videos;
  }

  /// 搜索监听
  void _onSearch() {
    final keyword = searchController.text;
    if (keyword.isEmpty) {
      displayedVideos.value = _historyService.videos;
      isSearching.value = false;
    } else {
      displayedVideos.value = _historyService.searchVideos(keyword);
      isSearching.value = true;
    }
  }

  /// 删除视频
  Future<void> deleteVideo(String id) async {
    await _historyService.deleteVideo(id);
    displayedVideos.value = _historyService.videos;
  }

  /// 清空所有视频
  Future<void> clearAllVideos() async {
    await _historyService.clearAll();
    displayedVideos.value = [];
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    final videos = _historyService.videos;
    final totalSize = videos.fold<int>(
      0,
      (sum, video) => sum + video.fileSize,
    );

    final totalDuration = videos.fold<int>(
      0,
      (sum, video) => sum + (video.duration ?? 0),
    );

    return {
      'count': videos.length,
      'totalSize': totalSize,
      'totalDuration': totalDuration,
    };
  }

  /// 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 格式化时长
  String formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
