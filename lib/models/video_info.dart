/// 视频信息模型
class VideoInfo {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String videoUrl;
  final String author;
  final String? platform;
  final int? duration;

  VideoInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.videoUrl,
    required this.author,
    this.platform,
    this.duration,
  });

  /// 从 JSON 创建
  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? json['desc'] ?? '无标题',
      description: json['description'] ?? json['desc'] ?? '',
      coverUrl: json['cover'] ?? json['coverUrl'] ?? json['thumbnail'] ?? '',
      videoUrl: json['videoUrl'] ?? json['url'] ?? json['playUrl'] ?? '',
      author: json['author'] ?? json['authorName'] ?? '未知作者',
      platform: json['platform'],
      duration: json['duration'] ?? json['durationMs'],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'videoUrl': videoUrl,
      'author': author,
      'platform': platform,
      'duration': duration,
    };
  }

  @override
  String toString() {
    return 'VideoInfo{id: $id, title: $title, author: $author, platform: $platform}';
  }
}
