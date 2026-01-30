/// 已下载视频模型
class DownloadedVideoModel {
  final String id;
  final String title;
  final String author;
  final String platform;
  final String description;
  final String coverUrl;
  final String videoUrl;
  final String localPath;
  final int fileSize;
  final DateTime downloadedAt;
  final int? duration;

  DownloadedVideoModel({
    required this.id,
    required this.title,
    required this.author,
    required this.platform,
    required this.description,
    required this.coverUrl,
    required this.videoUrl,
    required this.localPath,
    required this.fileSize,
    required this.downloadedAt,
    this.duration,
  });

  /// 从JSON创建
  factory DownloadedVideoModel.fromJson(Map<String, dynamic> json) {
    return DownloadedVideoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      platform: json['platform'] as String,
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String,
      videoUrl: json['videoUrl'] as String,
      localPath: json['localPath'] as String,
      fileSize: json['fileSize'] as int,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      duration: json['duration'] as int?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'platform': platform,
      'description': description,
      'coverUrl': coverUrl,
      'videoUrl': videoUrl,
      'localPath': localPath,
      'fileSize': fileSize,
      'downloadedAt': downloadedAt.toIso8601String(),
      'duration': duration,
    };
  }

  /// 格式化的文件大小
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 格式化的下载时间
  String get downloadedAtFormatted {
    final now = DateTime.now();
    final diff = now.difference(downloadedAt);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}天前';
    } else {
      return '${downloadedAt.year}-${downloadedAt.month.toString().padLeft(2, '0')}-${downloadedAt.day.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化的时长
  String get durationFormatted {
    if (duration == null) return '--:--';
    final seconds = (duration! ~/ 1000);
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 平台名称
  String get platformName {
    switch (platform) {
      case 'douyin':
        return '抖音';
      case 'tiktok':
        return 'TikTok';
      case 'youtube':
        return 'YouTube';
      case 'bilibili':
        return 'B站';
      default:
        return platform;
    }
  }

  /// 复制
  DownloadedVideoModel copyWith({
    String? id,
    String? title,
    String? author,
    String? platform,
    String? description,
    String? coverUrl,
    String? videoUrl,
    String? localPath,
    int? fileSize,
    DateTime? downloadedAt,
    int? duration,
  }) {
    return DownloadedVideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      platform: platform ?? this.platform,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      duration: duration ?? this.duration,
    );
  }
}
