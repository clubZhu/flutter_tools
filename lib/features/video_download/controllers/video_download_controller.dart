import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:calculator_app/models/video_info.dart';
import 'package:calculator_app/services/video_download_service.dart';
import 'package:calculator_app/features/video_download/services/download_history_service.dart';
import 'package:calculator_app/features/video_download/models/downloaded_video_model.dart';
import 'package:calculator_app/features/video_download/models/downloaded_image_model.dart';

/// 视频下载页面控制器
class VideoDownloadController extends GetxController
    with GetTickerProviderStateMixin {
  final VideoDownloadService _downloadService = VideoDownloadService();
  final DownloadHistoryService _historyService = DownloadHistoryService();

  // 文本和焦点控制器
  final TextEditingController urlController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode urlFocusNode = FocusNode();

  // 焦点状态
  final RxBool isUrlFocused = false.obs;

  // URL文本状态
  final RxBool hasUrlText = false.obs;

  // 动画控制器
  late AnimationController fadeController;
  late AnimationController scaleController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  // 响应式状态
  final Rx<VideoInfo?> videoInfo = Rx<VideoInfo?>(null);
  final Rx<VideoPlayerController?> videoController = Rx<VideoPlayerController?>(null);
  final RxBool isParsing = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);
  final Rx<File?> downloadedFile = Rx<File?>(null);
  final RxList<DownloadedImageModel> downloadedImages = <DownloadedImageModel>[].obs;
  final RxBool isDownloadingImages = false.obs;
  final RxDouble imageDownloadProgress = 0.0.obs;
  final RxInt currentImageIndex = 0.obs;
  CancelToken? cancelToken;

  @override
  void onInit() {
    super.onInit();
    _initHistoryService();
    _initAnimations();
    urlFocusNode.addListener(() {
      isUrlFocused.value = urlFocusNode.hasFocus;
    });
    urlController.addListener(() {
      hasUrlText.value = urlController.text.isNotEmpty;
    });
  }

  /// 初始化动画
  void _initAnimations() {
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeInOut),
    );
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.elasticOut),
    );

    fadeController.forward();
  }

  /// 初始化下载历史服务
  Future<void> _initHistoryService() async {
    await _historyService.init();
  }

  @override
  void onClose() {
    urlController.dispose();
    scrollController.dispose();
    urlFocusNode.dispose();
    videoController.value?.dispose();
    fadeController.dispose();
    scaleController.dispose();
    super.onClose();
  }

  /// 解析视频链接
  Future<void> parseVideoUrl() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入视频链接',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    // 如果正在下载，先取消下载
    if (isDownloading.value && cancelToken != null) {
      cancelToken!.cancel();
      cancelToken = null;
    }

    isParsing.value = true;
    errorMessage.value = null;
    videoInfo.value = null;
    videoController.value?.dispose();
    videoController.value = null;
    downloadProgress.value = 0.0;
    downloadedFile.value = null;
    downloadedImages.clear();
    isDownloading.value = false;
    isDownloadingImages.value = false;
    imageDownloadProgress.value = 0.0;
    currentImageIndex.value = 0;

    // 重置动画控制器，让动画重新播放
    scaleController.reset();

    try {
      final info = await _downloadService.parseVideoUrl(url);

      if (info != null) {
        videoInfo.value = info;
        isParsing.value = false;

        // 触发动画
        scaleController.forward();

        // 滚动到预览区域
        Future.delayed(const Duration(milliseconds: 300), () {
          scrollToPreview();
        });

        // 初始化视频播放器
        await initVideoPlayer(info.videoUrl);
      } else {
        isParsing.value = false;
        errorMessage.value = '解析失败，请检查链接是否正确';
        Get.snackbar(
          '错误',
          '解析视频失败，请检查链接',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isParsing.value = false;
      errorMessage.value = '解析失败: $e';
    }
  }

  /// 初始化视频播放器
  Future<void> initVideoPlayer(String videoUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();
      videoController.value = controller;
    } catch (e) {
      print('初始化视频播放器失败: $e');
    }
  }

  /// 滚动到预览区域
  void scrollToPreview() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 下载视频
  Future<void> downloadVideo() async {
    if (videoInfo.value == null) return;

    isDownloading.value = true;
    downloadProgress.value = 0.0;
    cancelToken = CancelToken();

    final fileName = _downloadService.generateSafeFileName(videoInfo.value!.title);

    try {
      final file = await _downloadService.downloadVideo(
        videoInfo.value!.videoUrl,
        fileName,
        onProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            downloadProgress.value = progress;
          }
        },
        cancelToken: cancelToken,
      );

      if (file != null) {
        // 添加到下载历史
        final fileSize = await file.length();
        final downloadedVideo = DownloadedVideoModel(
          id: '${videoInfo.value!.platform ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}',
          title: videoInfo.value!.title,
          author: videoInfo.value!.author,
          platform: videoInfo.value!.platform ?? 'unknown',
          description: videoInfo.value!.description,
          coverUrl: videoInfo.value!.coverUrl,
          videoUrl: videoInfo.value!.videoUrl,
          localPath: file.path,
          fileSize: fileSize,
          downloadedAt: DateTime.now(),
          duration: videoInfo.value!.duration,
        );
        await _historyService.addVideo(downloadedVideo);

        downloadedFile.value = file;
        isDownloading.value = false;

        Get.snackbar(
          '成功',
          '视频已下载完成',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          mainButton: TextButton(
            onPressed: () => Get.toNamed('/video-downloaded'),
            child: const Text('查看'),
          ),
        );
      } else {
        isDownloading.value = false;
        Get.snackbar(
          '失败',
          '下载失败，请重试',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isDownloading.value = false;
      Get.snackbar(
        '错误',
        '下载失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 取消下载
  void cancelDownload() {
    if (cancelToken != null) {
      _downloadService.cancelDownload(cancelToken!);
      isDownloading.value = false;
      isDownloadingImages.value = false;
      downloadProgress.value = 0.0;
      imageDownloadProgress.value = 0.0;
    }
  }

  /// 下载图片
  Future<void> downloadImages() async {
    if (videoInfo.value == null) return;

    final images = videoInfo.value!.images;
    if (images.isEmpty) {
      Get.snackbar(
        '提示',
        '该视频没有图片',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    isDownloadingImages.value = true;
    imageDownloadProgress.value = 0.0;
    currentImageIndex.value = 0;
    downloadedImages.clear();
    cancelToken = CancelToken();

    try {
      final imageUrls = images.map((img) => img.url).toList();
      final files = await _downloadService.downloadImages(
        imageUrls,
        videoInfo.value!.title,
        onProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            imageDownloadProgress.value = progress;
          }
        },
        onImageDownloaded: (current, total) {
          currentImageIndex.value = current;
        },
        cancelToken: cancelToken,
      );

      if (files.isNotEmpty) {
        // 将下载的文件转换为模型
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final fileSize = await file.length();
          final imageModel = DownloadedImageModel.fromVideoInfo(
            localPath: file.path,
            imageInfo: images[i],
            videoId: videoInfo.value!.id,
            videoTitle: videoInfo.value!.title,
            videoAuthor: videoInfo.value!.author,
            platform: videoInfo.value!.platform ?? 'unknown',
            fileSize: fileSize,
          );
          downloadedImages.add(imageModel);
        }

        isDownloadingImages.value = false;

        Get.snackbar(
          '成功',
          '已下载 ${files.length} 张图片',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        isDownloadingImages.value = false;
        Get.snackbar(
          '失败',
          '图片下载失败，请重试',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isDownloadingImages.value = false;
      Get.snackbar(
        '错误',
        '下载图片失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 下载视频和图片
  Future<void> downloadVideoAndImages() async {
    if (videoInfo.value == null) return;

    // 先下载视频
    await downloadVideo();

    // 如果有图片，继续下载图片
    if (videoInfo.value!.images.isNotEmpty) {
      await downloadImages();
    }
  }

  /// 切换视频播放状态
  void toggleVideoPlayback() {
    final controller = videoController.value;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    update();
  }

  /// 清空URL输入框
  void clearUrl() {
    urlController.clear();
    urlFocusNode.unfocus();
  }

  /// 重置下载状态
  void resetDownloadState() {
    downloadedFile.value = null;
  }

  /// 获取平台图标
  IconData getPlatformIcon(String? platform) {
    switch (platform) {
      case 'douyin':
        return Icons.music_note;
      case 'tiktok':
        return Icons.music_video;
      case 'bilibili':
        return Icons.tv;
      case 'weibo':
        return Icons.wechat;
      case 'kuaishou':
        return Icons.video_library;
      default:
        return Icons.video_call;
    }
  }

  /// 获取平台名称
  String getPlatformName(String? platform) {
    switch (platform) {
      case 'douyin':
        return '抖音';
      case 'tiktok':
        return 'TikTok';
      case 'bilibili':
        return 'B站';
      case 'weibo':
        return '微博';
      case 'kuaishou':
        return '快手';
      default:
        return '未知平台';
    }
  }

  /// 格式化时长
  String formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
