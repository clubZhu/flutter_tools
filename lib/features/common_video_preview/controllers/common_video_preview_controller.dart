import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:calculator_app/features/video_download/models/downloaded_video_model.dart';
import 'package:calculator_app/features/video_recording/models/video_recording_model.dart';

/// iOS 相册风格视频预览控制器
class CommonVideoPreviewController extends GetxController {
  // 视频列表
  final RxList<dynamic> videos = <dynamic>[].obs;
  final RxInt currentIndex = 0.obs;

  // 当前视频
  dynamic get currentVideo => videos.value.isNotEmpty ? videos.value[currentIndex.value] : null;

  // 是否是录制视频
  bool get isRecordingVideo => currentVideo is VideoRecordingModel;

  // 视频信息
  String get videoId => isRecordingVideo ? currentVideo?.id ?? '' : currentVideo?.id ?? '';
  String get videoTitle => isRecordingVideo ? currentVideo?.name ?? '' : currentVideo?.title ?? '';
  String get videoSubtitle => isRecordingVideo
      ? '${currentVideo?.durationFormatted ?? ''} · ${currentVideo?.fileSizeFormatted ?? ''}'
      : '${currentVideo?.author ?? ''} · ${currentVideo?.durationFormatted ?? ''}';
  String get videoPath => isRecordingVideo ? currentVideo?.filePath ?? '' : currentVideo?.localPath ?? '';

  // PageController 用于 PageView
  late PageController pageController;

  // 视频播放器缓存（每个视频一个控制器）
  final Map<int, VideoPlayerController> _videoControllers = {};
  final RxBool _isControllersReady = false.obs;

  // 状态
  final RxBool showControls = false.obs;
  final RxBool isScrubbing = false.obs;
  final RxDouble scrubPosition = 0.0.obs;
  final RxBool wasPlayingBeforeScrubbing = false.obs;

  // 进度条显示控制
  final RxBool showProgressBar = false.obs;
  Timer? _progressBarTimer;

  // 缩放控制器
  late TransformationController transformationController;

  // 进度条 key
  final GlobalKey progressBarKey = GlobalKey();

  @override
  void onInit() {
    super.onInit();
    transformationController = TransformationController();
    _parseArguments();
    // 初始化 PageController
    pageController = PageController(initialPage: currentIndex.value, viewportFraction: 1.0);
    _initializeControllers();
  }

  @override
  void onClose() {
    // 释放所有视频控制器
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    transformationController.dispose();
    pageController.dispose();
    _progressBarTimer?.cancel();
    super.onClose();
  }

  /// 解析路由参数
  void _parseArguments() {
    final arguments = Get.arguments;

    if (arguments is Map) {
      final videoList = arguments['videos'];
      final index = arguments['index'] ?? 0;

      if (videoList is List) {
        videos.value = videoList;
        currentIndex.value = index as int;
        return;
      }
    }

    // 单个视频模式
    if (arguments is VideoRecordingModel) {
      videos.value = [arguments];
      currentIndex.value = 0;
    } else if (arguments is DownloadedVideoModel) {
      videos.value = [arguments];
      currentIndex.value = 0;
    }
  }

  /// 初始化视频控制器
  Future<void> _initializeControllers() async {
    // 预加载当前、上一个、下一个视频
    final indexesToLoad = [currentIndex.value];
    if (currentIndex.value > 0) {
      indexesToLoad.add(currentIndex.value - 1);
    }
    if (currentIndex.value < videos.value.length - 1) {
      indexesToLoad.add(currentIndex.value + 1);
    }

    for (var index in indexesToLoad) {
      await _initializeController(index);
    }

    _isControllersReady.value = true;
    // 自动播放当前视频
    final currentController = _videoControllers[currentIndex.value];
    if (currentController != null) {
      currentController.play();
    }
  }

  /// 初始化单个视频控制器
  Future<void> _initializeController(int index) async {
    if (_videoControllers.containsKey(index)) return;

    final video = videos.value[index];
    final path = isRecordingVideo
        ? (video as VideoRecordingModel).filePath
        : (video as DownloadedVideoModel).localPath;

    if (path.isEmpty) return;

    try {
      final file = File(path);
      if (await file.exists()) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        _videoControllers[index] = controller;
      }
    } catch (e) {
      print('初始化视频失败: $e');
    }
  }

  /// 获取指定索引的视频控制器
  VideoPlayerController? getVideoController(int index) {
    return _videoControllers[index];
  }

  /// 切换到上一个视频
  void previousVideo() {
    if (currentIndex.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 切换到下一个视频
  void nextVideo() {
    if (currentIndex.value < videos.value.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 是否可以翻页
  bool get canGoPrevious => currentIndex.value > 0;
  bool get canGoNext => currentIndex.value < videos.value.length - 1;

  /// 页面变化回调
  void onPageChanged(int index) {
    // 暂停旧视频
    final oldController = _videoControllers[currentIndex.value];
    if (oldController != null) {
      oldController.pause();
    }

    // 更新索引
    currentIndex.value = index;

    // 播放新视频
    final newController = _videoControllers[index];
    if (newController != null) {
      newController.play();
    }

    // 预加载相邻视频
    _preloadAdjacentVideos();
  }

  /// 预加载相邻视频
  void _preloadAdjacentVideos() async {
    // 加载下一个
    if (currentIndex.value < videos.value.length - 1) {
      await _initializeController(currentIndex.value + 1);
    }
    // 加载上一个
    if (currentIndex.value > 0) {
      await _initializeController(currentIndex.value - 1);
    }

    // 释放远离的视频控制器（节省内存）
    final toRemove = <int>[];
    for (var key in _videoControllers.keys) {
      if ((key - currentIndex.value).abs() > 2) {
        toRemove.add(key);
      }
    }
    for (var key in toRemove) {
      _videoControllers[key]?.dispose();
      _videoControllers.remove(key);
    }
  }

  /// 切换播放/暂停
  void togglePlayPause() {
    final controller = _videoControllers[currentIndex.value];
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      showControls.value = true;
    } else {
      controller.play();
      showControls.value = false;
    }
  }

  /// 更新进度条位置
  void updateScrubPosition(Offset globalPosition) {
    try {
      final RenderBox? renderBox =
          progressBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(globalPosition);
      final double ratio = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);

      final controller = _videoControllers[currentIndex.value];
      if (controller != null) {
        final duration = controller.value.duration.inMilliseconds.toDouble();
        scrubPosition.value = ratio * duration;
      }
    } catch (e) {
      print('更新进度条位置失败: $e');
    }
  }

  /// 开始拖动进度条
  void startScrubbing(Offset globalPosition) {
    final controller = _videoControllers[currentIndex.value];
    if (controller == null) return;

    wasPlayingBeforeScrubbing.value = controller.value.isPlaying;
    isScrubbing.value = true;
    controller.pause();
    updateScrubPosition(globalPosition);
  }

  /// 更新拖动位置
  void updateScrubbing(Offset globalPosition) {
    updateScrubPosition(globalPosition);
  }

  /// 结束拖动
  void endScrubbing() {
    final controller = _videoControllers[currentIndex.value];
    if (controller == null) return;

    controller.seekTo(Duration(milliseconds: scrubPosition.value.toInt()));
    isScrubbing.value = false;
    if (wasPlayingBeforeScrubbing.value) {
      controller.play();
    }
  }

  /// 格式化时长
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours);
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  /// 获取当前播放位置
  double get currentPosition {
    final controller = _videoControllers[currentIndex.value];
    if (controller == null) return 0.0;
    return isScrubbing.value
        ? scrubPosition.value
        : controller.value.position.inMilliseconds.toDouble();
  }

  /// 获取总时长
  double get totalDuration {
    final controller = _videoControllers[currentIndex.value];
    if (controller == null) return 0.0;
    return controller.value.duration.inMilliseconds.toDouble();
  }

  /// 获取缓冲位置
  double get bufferedPosition {
    final controller = _videoControllers[currentIndex.value];
    if (controller == null) return 0.0;
    return controller.value.buffered.isNotEmpty
        ? controller.value.buffered.last.end.inMilliseconds.toDouble()
        : 0.0;
  }

  /// 是否正在播放
  bool get isPlaying {
    final controller = _videoControllers[currentIndex.value];
    return controller?.value.isPlaying ?? false;
  }

  /// 获取当前时长
  Duration get duration {
    final controller = _videoControllers[currentIndex.value];
    return controller?.value.duration ?? Duration.zero;
  }

  /// 是否已准备好
  bool get isControllersReady => _isControllersReady.value;

  /// 显示进度条
  void showProgressBarOverlay() {
    showProgressBar.value = true;
    _startProgressBarTimer();
  }

  /// 启动进度条自动隐藏计时器
  void _startProgressBarTimer() {
    _progressBarTimer?.cancel();
    _progressBarTimer = Timer(const Duration(seconds: 3), () {
      showProgressBar.value = false;
    });
  }

  /// 手动隐藏进度条
  void hideProgressBar() {
    showProgressBar.value = false;
    _progressBarTimer?.cancel();
  }

  /// 重置进度条计时器（有新操作时调用）
  void resetProgressBarTimer() {
    if (showProgressBar.value) {
      _startProgressBarTimer();
    }
  }
}
