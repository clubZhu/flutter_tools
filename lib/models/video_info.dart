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
  final List<ImageInfo> images; // 图片列表

  VideoInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.videoUrl,
    required this.author,
    this.platform,
    this.duration,
    this.images = const [],
  });

  /// 从 JSON 创建
  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    // 解析图片列表
    final List<dynamic> imagesData = json['images'] ?? [];
    final List<ImageInfo> images = imagesData.map((img) {
      return ImageInfo(
        url: img['url'] ?? img['cover_url'] ?? img['cover'] ?? '',
      );
    }).toList();

    return VideoInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? json['desc'] ?? '无标题',
      description: json['description'] ?? json['desc'] ?? '',
      coverUrl: json['cover'] ?? json['coverUrl'] ?? json['thumbnail'] ?? '',
      videoUrl: json['videoUrl'] ?? json['url'] ?? json['playUrl'] ?? '',
      author: json['author'] ?? json['authorName'] ?? '未知作者',
      platform: json['platform'],
      duration: json['duration'] ?? json['durationMs'],
      images: images,
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
      'images': images.map((img) => img.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'VideoInfo{id: $id, title: $title, author: $author, platform: $platform, images: ${images.length}}';
  }
}

/// 图片信息模型
class ImageInfo {
  final String url;

  ImageInfo({
    required this.url,
  });

  /// 从 JSON 创建
  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      url: json['url'] ?? json['cover_url'] ?? json['cover'] ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }

  @override
  String toString() => 'ImageInfo{url: $url}';
}
