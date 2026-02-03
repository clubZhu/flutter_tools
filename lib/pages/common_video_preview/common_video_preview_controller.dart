import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../features/video_download/models/downloaded_video_model.dart';
import '../../../models/video_recording_model.dart';

/// 视频预览控制器 - 使用 GetX 状态管理
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
  String get heroTag => isRecordingVideo
      ? 'recording_cover_${currentVideo?.id ?? ''}'
      : 'video_cover_${currentVideo?.id ?? ''}';

  // 视频播放器
  final Rx<VideoPlayerController?> controller = Rx<VideoPlayerController?>(null);

  // 状态
  final RxBool isInitialized = false.obs;
  final RxBool hasError = false.obs;
  final RxBool showControls = false.obs;
  final RxBool isFullScreen = false.obs;
  final RxBool isScrubbing = false.obs;
  final RxDouble scrubPosition = 0.0.obs;
  final RxBool wasPlayingBeforeScrubbing = false.obs;

  // 缩放控制器
  late TransformationController transformationController;

  // 进度条 key
  final GlobalKey progressBarKey = GlobalKey();

  // PageController 用于 PageView
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    transformationController = TransformationController();
    // 先解析参数，设置好 currentIndex
    _parseArguments();
    // 再用正确的索引创建 PageController
    pageController = PageController(initialPage: currentIndex.value);
    _initializeVideo();
  }

  @override
  void onClose() {
    controller.value?.dispose();
    transformationController.dispose();
    pageController.dispose();
    _restoreScreenOrientation();
    super.onClose();
  }

  /// 解析路由参数
  void _parseArguments() {
    final arguments = Get.arguments;

    // 支持两种传参方式：
    // 1. 单个视频对象
    // 2. 包含视频列表和索引的 Map: {'videos': [...], 'index': 0}

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

  /// 初始化视频
  Future<void> _initializeVideo({bool autoPlay = true}) async {
    if (videoPath.isEmpty) {
      hasError.value = true;
      return;
    }

    try {
      final file = File(videoPath);
      if (await file.exists()) {
        controller.value = VideoPlayerController.file(file);
        await controller.value!.initialize();

        controller.value!.addListener(() {
          // 使用 update() 而不是 setState()
          // GetX 会自动监听 VideoPlayerController 的变化
        });

        isInitialized.value = true;

        // 只在需要时自动播放
        if (autoPlay) {
          controller.value!.play();
        }
      } else {
        hasError.value = true;
      }
    } catch (e) {
      hasError.value = true;
    }
  }

  /// 切换到上一个视频
  void previousVideo() {
    if (currentIndex.value > 0) {
      _changeVideo(currentIndex.value - 1);
    }
  }

  /// 切换到下一个视频
  void nextVideo() {
    if (currentIndex.value < videos.value.length - 1) {
      _changeVideo(currentIndex.value + 1);
    }
  }

  /// 切换视频
  void _changeVideo(int index) async {
    // 释放当前视频资源
    await controller.value?.pause();
    await controller.value?.dispose();
    controller.value = null;

    // 重置状态
    isInitialized.value = false;
    hasError.value = false;
    showControls.value = false;
    isScrubbing.value = false;
    scrubPosition.value = 0.0;

    // 重置缩放
    transformationController.value = Matrix4.identity();

    // 更新索引
    currentIndex.value = index;

    // 初始化新视频（自动播放）
    await _initializeVideo(autoPlay: true);
  }

  /// PageView 页面变化回调
  void onPageChanged(int index) {
    // 只有当索引真正改变时才切换视频
    if (index != currentIndex.value) {
      _changeVideo(index);
    }
  }

  /// 是否可以翻页
  bool get canGoPrevious => currentIndex.value > 0;
  bool get canGoNext => currentIndex.value < videos.value.length - 1;

  /// 切换播放/暂停
  void togglePlayPause() {
    if (controller.value == null) return;

    if (controller.value!.value.isPlaying) {
      controller.value!.pause();
      showControls.value = true;
    } else {
      controller.value!.play();
      showControls.value = false;
    }
  }

  /// 切换全屏
  void toggleFullScreen() {
    isFullScreen.value = !isFullScreen.value;

    if (isFullScreen.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _restoreScreenOrientation();
      transformationController.value = Matrix4.identity();
    }
  }

  /// 恢复屏幕方向
  void _restoreScreenOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// 更新进度条位置
  void updateScrubPosition(Offset globalPosition) {
    try {
      final RenderBox? renderBox =
          progressBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(globalPosition);
      final double ratio = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);

      if (controller.value != null) {
        final duration = controller.value!.value.duration.inMilliseconds.toDouble();
        scrubPosition.value = ratio * duration;
      }
    } catch (e) {
      print('更新进度条位置失败: $e');
    }
  }

  /// 开始拖动进度条
  void startScrubbing(Offset globalPosition) {
    if (controller.value == null) return;
    wasPlayingBeforeScrubbing.value = controller.value!.value.isPlaying;
    isScrubbing.value = true;
    controller.value!.pause();
    updateScrubPosition(globalPosition);
  }

  /// 更新拖动位置
  void updateScrubbing(Offset globalPosition) {
    updateScrubPosition(globalPosition);
  }

  /// 结束拖动
  void endScrubbing() {
    if (controller.value == null) return;
    controller.value!.seekTo(Duration(milliseconds: scrubPosition.value.toInt()));
    isScrubbing.value = false;
    if (wasPlayingBeforeScrubbing.value) {
      controller.value!.play();
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
    if (controller.value == null) return 0.0;
    return isScrubbing.value
        ? scrubPosition.value
        : controller.value!.value.position.inMilliseconds.toDouble();
  }

  /// 获取总时长
  double get totalDuration {
    if (controller.value == null) return 0.0;
    return controller.value!.value.duration.inMilliseconds.toDouble();
  }

  /// 获取缓冲位置
  double get bufferedPosition {
    if (controller.value == null) return 0.0;
    return controller.value!.value.buffered.isNotEmpty
        ? controller.value!.value.buffered.last.end.inMilliseconds.toDouble()
        : 0.0;
  }

  /// 是否正在播放
  bool get isPlaying {
    return controller.value?.value.isPlaying ?? false;
  }

  /// 获取当前时长
  Duration get duration {
    return controller.value?.value.duration ?? Duration.zero;
  }
}
