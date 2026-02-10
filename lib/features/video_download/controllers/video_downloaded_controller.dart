import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../services/download_history_service.dart';
import '../models/downloaded_video_model.dart';
import '../models/downloaded_image_model.dart';

/// 视频已下载页面控制器
class VideoDownloadedController extends GetxController
    with GetTickerProviderStateMixin {
  final DownloadHistoryService _historyService = DownloadHistoryService();
  final TextEditingController searchController = TextEditingController();

  // Tab控制器
  late TabController tabController;
  final RxInt currentTab = 0.obs;

  // 响应式变量
  final RxList<DownloadedVideoModel> displayedVideos = <DownloadedVideoModel>[].obs;
  final RxList<DownloadedImageModel> displayedImages = <DownloadedImageModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoading = true.obs;

  // 多选状态
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedImageIds = <String>{}.obs;

  // 动画控制器
  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void onInit() {
    super.onInit();
    // 初始化TabController
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      currentTab.value = tabController.index;
    });
    _initAnimations();
    initData();
    searchController.addListener(_onSearch);
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearch);
    searchController.dispose();
    tabController.dispose();
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
    displayedImages.value = _historyService.images;
    isLoading.value = false;
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _historyService.refresh();
    displayedVideos.value = _historyService.videos;
    displayedImages.value = _historyService.images;
  }

  /// 搜索监听
  void _onSearch() {
    final keyword = searchController.text;
    if (keyword.isEmpty) {
      displayedVideos.value = _historyService.videos;
      displayedImages.value = _historyService.images;
      isSearching.value = false;
    } else {
      displayedVideos.value = _historyService.searchVideos(keyword);
      displayedImages.value = _historyService.searchImages(keyword);
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

  /// 删除图片
  Future<void> deleteImage(String id) async {
    await _historyService.deleteImage(id);
    displayedImages.value = _historyService.images;
  }

  /// 开启多选模式
  void enableSelectionMode() {
    isSelectionMode.value = true;
    selectedImageIds.clear();
  }

  /// 关闭多选模式
  void disableSelectionMode() {
    isSelectionMode.value = false;
    selectedImageIds.clear();
  }

  /// 切换图片选择状态
  void toggleImageSelection(String imageId) {
    if (selectedImageIds.contains(imageId)) {
      selectedImageIds.remove(imageId);
      if (selectedImageIds.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedImageIds.add(imageId);
    }
  }

  /// 检查图片是否被选中
  bool isImageSelected(String imageId) {
    return selectedImageIds.contains(imageId);
  }

  /// 全选当前图片
  void selectAllImages() {
    selectedImageIds.clear();
    selectedImageIds.addAll(displayedImages.map((e) => e.id));
  }

  /// 取消全选
  void deselectAllImages() {
    selectedImageIds.clear();
  }

  /// 获取选中的图片
  List<DownloadedImageModel> get selectedImages =>
      displayedImages.where((img) => selectedImageIds.contains(img.id)).toList();

  /// 批量删除图片
  Future<void> deleteSelectedImages() async {
    if (selectedImageIds.isEmpty) return;

    for (final id in selectedImageIds) {
      await _historyService.deleteImage(id);
    }

    selectedImageIds.clear();
    isSelectionMode.value = false;
    displayedImages.value = _historyService.images;
  }

  /// 批量分享图片
  Future<void> shareSelectedImages() async {
    if (selectedImageIds.isEmpty) return;

    try {
      final images = selectedImages;
      final files = images.map((img) => XFile(img.localPath)).toList();

      await Share.shareXFiles(
        files,
        text: '分享 ${images.length} 张图片',
      );

      // 分享后退出选择模式
      disableSelectionMode();
    } catch (e) {
      Get.snackbar(
        '错误',
        '分享失败: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  /// 选择图片后自动开启选择模式
  void selectImageAndEnterMode(String imageId) {
    if (!isSelectionMode.value) {
      enableSelectionMode();
    }
    toggleImageSelection(imageId);
  }
}
