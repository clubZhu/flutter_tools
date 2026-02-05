import 'package:flutter/material.dart';
import '../../models/downloaded_video_model.dart';

/// 视频详情对话框
class VideoDetailsDialog extends StatelessWidget {
  final DownloadedVideoModel video;

  const VideoDetailsDialog({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('视频详情'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DetailRow(label: '标题', value: video.title),
            DetailRow(label: '作者', value: video.author),
            DetailRow(label: '平台', value: video.platformName),
            DetailRow(label: '时长', value: video.durationFormatted),
            DetailRow(label: '大小', value: video.fileSizeFormatted),
            DetailRow(label: '下载时间', value: video.downloadedAtFormatted),
            if (video.description.isNotEmpty)
              DetailRow(label: '描述', value: video.description),
            DetailRow(label: '视频链接', value: video.videoUrl),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

/// 详情行组件
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
