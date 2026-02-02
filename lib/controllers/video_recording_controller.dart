import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/video_recording_model.dart';
import '../services/video_recording_service.dart';

/// 视频录制控制器
class VideoRecordingController extends GetxController {
  final VideoRecordingService _recordingService = VideoRecordingService();

  // 响应式变量
  final RxBool isInitialized = false.obs;
  final RxBool isRecording = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt recordingDuration = 0.obs;
  final RxList<VideoRecordingModel> videoList = <VideoRecordingModel>[].obs;
  final RxInt cameraChangeCounter = 0.obs; // 用于强制刷新 UI
  final RxBool isSwitchingCamera = false.obs; // 相机切换状态

  // 相机控制器
  CameraController? get cameraController => _recordingService.controller;

  // 录制定时器
  Timer? _recordingTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
    _loadVideoList();
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    _recordingService.dispose();
    // 确保在控制器关闭时禁用 wakelock
    WakelockPlus.disable();
    super.onClose();
  }

  /// 初始化相机
  Future<void> _initializeCamera() async {
    try {
      hasError.value = false;
      errorMessage.value = '';

      final success = await _recordingService.initializeCamera();
      if (success) {
        isInitialized.value = true;
      } else {
        hasError.value = true;
        errorMessage.value = '相机初始化失败，请检查权限设置';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '相机初始化失败: $e';
    }
  }

  /// 加载视频列表
  Future<void> _loadVideoList() async {
    try {
      final videos = await _recordingService.getAllVideos();
      videoList.assignAll(videos);
    } catch (e) {
      print('加载视频列表失败: $e');
    }
  }

  /// 开始录制
  Future<bool> startRecording() async {
    try {
      if (!isInitialized.value) {
        Get.snackbar('错误', '相机未初始化');
        return false;
      }

      // 启用 Wakelock 以保持屏幕常亮，防止后台限制
      await WakelockPlus.enable();

      final success = await _recordingService.startRecording();
      if (success) {
        isRecording.value = true;
        recordingDuration.value = 0;

        // 启动计时器
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          recordingDuration.value++;
          _recordingService.updateRecordingDuration();
        });

        // Get.snackbar('开始录制', '视频录制已开始');
        return true;
      } else {
        // 如果录制失败，禁用 wakelock
        await WakelockPlus.disable();
        Get.snackbar('错误', '开始录制失败');
        return false;
      }
    } catch (e) {
      // 如果发生异常，禁用 wakelock
      await WakelockPlus.disable();
      Get.snackbar('错误', '开始录制失败: $e');
      return false;
    }
  }

  /// 停止录制
  Future<void> stopRecording() async {
    try {
      if (!isRecording.value) return;

      // 取消计时器
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final videoRecording = await _recordingService.stopRecording();
      isRecording.value = false;

      // 禁用 Wakelock
      await WakelockPlus.disable();

      if (videoRecording != null) {
        // 刷新视频列表
        await _loadVideoList();
        /*Get.snackbar(
          '录制完成',
          '视频已保存，时长: ${videoRecording.durationFormatted}',
          duration: const Duration(seconds: 2),
        );*/

        // 跳转到预览页面
        Get.toNamed('/video-preview', arguments: videoRecording);
      } else {
        Get.snackbar('错误', '保存视频失败');
      }
    } catch (e) {
      isRecording.value = false;
      // 确保在异常情况下也禁用 wakelock
      await WakelockPlus.disable();
      Get.snackbar('错误', '停止录制失败: $e');
    }
  }

  /// 切换相机
  Future<void> switchCamera() async {
    try {
      // 如果正在录制，不允许切换相机
      if (isRecording.value) {
        Get.snackbar(
          '提示',
          '录制时无法切换相机',
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // 标记正在切换相机（不隐藏当前预览）
      isSwitchingCamera.value = true;

      await _recordingService.switchCamera();

      // 强制刷新 UI
      cameraChangeCounter.value++;
      isSwitchingCamera.value = false;
    } catch (e) {
      Get.snackbar('错误', '切换相机失败: $e');
      isSwitchingCamera.value = false;
    }
  }

  /// 删除视频
  Future<void> deleteVideo(String videoId) async {
    try {
      final success = await _recordingService.deleteVideo(videoId);
      if (success) {
        await _loadVideoList();
        // Get.snackbar('成功', '视频已删除');
      } else {
        Get.snackbar('错误', '删除视频失败');
      }
    } catch (e) {
      Get.snackbar('错误', '删除视频失败: $e');
    }
  }

  /// 更新视频名称
  Future<void> updateVideoName(String videoId, String newName) async {
    try {
      final success = await _recordingService.updateVideoName(videoId, newName);
      if (success) {
        await _loadVideoList();
        Get.snackbar('成功', '视频名称已更新');
      } else {
        Get.snackbar('错误', '更新视频名称失败');
      }
    } catch (e) {
      Get.snackbar('错误', '更新视频名称失败: $e');
    }
  }

  /// 刷新视频列表
  Future<void> refreshVideoList() async {
    await _loadVideoList();
  }

  /// 格式化录制时长
  String get formattedDuration {
    final hours = recordingDuration.value ~/ 3600;
    final minutes = (recordingDuration.value % 3600) ~/ 60;
    final seconds = recordingDuration.value % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
