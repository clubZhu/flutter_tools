import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../models/video_recording_model.dart';
import 'video_database_service.dart';

/// 视频录制服务
class VideoRecordingService {
  static final VideoRecordingService _instance = VideoRecordingService._internal();
  factory VideoRecordingService() => _instance;
  VideoRecordingService._internal();

  final VideoDatabaseService _databaseService = VideoDatabaseService();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  int _recordingDuration = 0;

  // 获取相机列表
  List<CameraDescription>? get cameras => _cameras;

  // 获取当前控制器
  CameraController? get controller => _controller;

  // 是否正在录制
  bool get isRecording => _isRecording;

  // 录制时长
  int get recordingDuration => _recordingDuration;

  /// 初始化相机
  Future<bool> initializeCamera() async {
    try {
      // 请求相机和麦克风权限
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        return false;
      }

      // 获取可用相机
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // 初始化后置相机
      await _initCamera(_cameras!.first);
      return true;
    } catch (e) {
      print('初始化相机失败: $e');
      return false;
    }
  }

  /// 初始化指定相机
  Future<void> _initCamera(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
  }

  /// 切换相机（前置/后置）
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      final currentCamera = _controller?.description;
      final currentIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == currentCamera?.lensDirection,
      );

      final nextIndex = (currentIndex + 1) % _cameras!.length;

      // 释放旧相机
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // 等待确保相机完全释放
      await Future.delayed(const Duration(milliseconds: 200));

      // 初始化新相机
      await _initCamera(_cameras![nextIndex]);
    } catch (e) {
      print('切换相机失败: $e');
      rethrow;
    }
  }

  /// 开始录制视频
  Future<bool> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    if (_isRecording) {
      return false;
    }

    try {
      // 获取应用文档目录
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videosDir = path.join(appDir.path, 'videos');
      await Directory(videosDir).create(recursive: true);

      // 开始录制（使用新的 API）
      await _controller!.startVideoRecording();
      _isRecording = true;
      _recordingDuration = 0;
      return true;
    } catch (e) {
      print('开始录制失败: $e');
      return false;
    }
  }

  /// 停止录制视频
  Future<VideoRecordingModel?> stopRecording() async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      // 使用新的 API 停止录制
      final XFile videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // 获取文件信息
      final File file = File(videoFile.path);
      final int fileSize = await file.length();

      // 创建视频记录模型
      final videoRecording = VideoRecordingModel(
        id: const Uuid().v4(),
        filePath: videoFile.path,
        thumbnailPath: await _generateThumbnail(videoFile.path),
        name: '视频_${DateTime.now().millisecondsSinceEpoch}',
        duration: _recordingDuration,
        fileSize: fileSize,
        createdAt: DateTime.now(),
      );

      // 保存到数据库
      await _databaseService.insertVideo(videoRecording);

      return videoRecording;
    } catch (e) {
      print('停止录制失败: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 删除视频
  Future<bool> deleteVideo(String videoId) async {
    try {
      // 从数据库获取视频信息
      final video = await _databaseService.getVideoById(videoId);
      if (video == null) return false;

      // 删除文件
      final file = File(video.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 删除缩略图
      if (video.thumbnailPath.isNotEmpty) {
        final thumbnailFile = File(video.thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // 从数据库删除记录
      await _databaseService.deleteVideo(videoId);
      return true;
    } catch (e) {
      print('删除视频失败: $e');
      return false;
    }
  }

  /// 更新视频名称
  Future<bool> updateVideoName(String videoId, String newName) async {
    try {
      final video = await _databaseService.getVideoById(videoId);
      if (video == null) return false;

      final updatedVideo = video.copyWith(name: newName);
      await _databaseService.updateVideo(updatedVideo);
      return true;
    } catch (e) {
      print('更新视频名称失败: $e');
      return false;
    }
  }

  /// 获取所有视频记录
  Future<List<VideoRecordingModel>> getAllVideos() async {
    return await _databaseService.getAllVideos();
  }

  /// 释放资源
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isRecording = false;
  }

  /// 更新录制时长
  void updateRecordingDuration() {
    if (_isRecording) {
      _recordingDuration++;
    }
  }

  /// 生成视频缩略图
  Future<String> _generateThumbnail(String videoPath) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory('${appDir.path}/thumbnails');

      // 创建缩略图目录
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // 生成缩略图文件名
      final fileName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath = '${thumbnailDir.path}/$fileName.jpg';

      // 生成缩略图
      final uint8list = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 320,
        quality: 75,
      );

      // 检查是否成功生成
      if (uint8list == null || uint8list.isEmpty) {
        print('缩略图生成失败: 返回数据为空');
        return '';
      }

      // 保存缩略图
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(uint8list);

      return thumbnailPath;
    } catch (e) {
      print('生成缩略图失败: $e');
      return ''; // 失败时返回空字符串
    }
  }
}
