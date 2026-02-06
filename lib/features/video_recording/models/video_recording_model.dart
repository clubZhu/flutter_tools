/// 视频录制模型
class VideoRecordingModel {
  final String id;
  final String filePath;
  final String thumbnailPath;
  final String name;
  final int duration; // 时长（秒）
  final int fileSize; // 文件大小（字节）
  final DateTime createdAt;
  final DateTime? modifiedAt;

  VideoRecordingModel({
    required this.id,
    required this.filePath,
    required this.thumbnailPath,
    required this.name,
    required this.duration,
    required this.fileSize,
    required this.createdAt,
    this.modifiedAt,
  });

  /// 从数据库Map创建模型
  factory VideoRecordingModel.fromMap(Map<String, dynamic> map) {
    return VideoRecordingModel(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String,
      name: map['name'] as String,
      duration: map['duration'] as int,
      fileSize: map['fileSize'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      modifiedAt: map['modifiedAt'] != null
          ? DateTime.parse(map['modifiedAt'] as String)
          : null,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'name': name,
      'duration': duration,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  /// 复制并更新部分字段
  VideoRecordingModel copyWith({
    String? id,
    String? filePath,
    String? thumbnailPath,
    String? name,
    int? duration,
    int? fileSize,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return VideoRecordingModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// 格式化文件大小显示
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 格式化时长显示
  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化创建时间显示
  String get createdAtFormatted {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }
  }
}
