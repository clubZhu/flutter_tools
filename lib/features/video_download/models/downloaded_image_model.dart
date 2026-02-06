import 'package:calculator_app/models/video_info.dart';

/// 已下载图片模型
class DownloadedImageModel {
  final String id;
  final String videoId;
  final String videoTitle;
  final String videoAuthor;
  final String platform;
  final String imageUrl;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSize;

  DownloadedImageModel({
    required this.id,
    required this.videoId,
    required this.videoTitle,
    required this.videoAuthor,
    required this.platform,
    required this.imageUrl,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSize,
  });

  /// 从 VideoInfo 和本地路径创建
  factory DownloadedImageModel.fromVideoInfo({
    required String localPath,
    required ImageInfo imageInfo,
    required String videoId,
    required String videoTitle,
    required String videoAuthor,
    required String platform,
    required int fileSize,
  }) {
    return DownloadedImageModel(
      id: '${videoId}_${imageInfo.url.hashCode}',
      videoId: videoId,
      videoTitle: videoTitle,
      videoAuthor: videoAuthor,
      platform: platform,
      imageUrl: imageInfo.url,
      localPath: localPath,
      downloadedAt: DateTime.now(),
      fileSize: fileSize,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'videoTitle': videoTitle,
      'videoAuthor': videoAuthor,
      'platform': platform,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'downloadedAt': downloadedAt.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  /// 从 JSON 创建
  factory DownloadedImageModel.fromJson(Map<String, dynamic> json) {
    return DownloadedImageModel(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      videoTitle: json['videoTitle'] as String,
      videoAuthor: json['videoAuthor'] as String,
      platform: json['platform'] as String,
      imageUrl: json['imageUrl'] as String,
      localPath: json['localPath'] as String,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      fileSize: json['fileSize'] as int,
    );
  }

  /// 格式化文件大小
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  @override
  String toString() {
    return 'DownloadedImageModel{id: $id, videoTitle: $videoTitle}';
  }
}
