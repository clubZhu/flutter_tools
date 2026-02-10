import 'package:flutter/material.dart';
import '../../models/downloaded_video_model.dart';
import 'video_thumbnail.dart';
import 'video_info.dart';
import 'video_labels.dart';
import 'video_menu_button.dart';

/// 视频卡片组件 - 简洁舒适的设计
class VideoCard extends StatefulWidget {
  final DownloadedVideoModel video;
  final int index;
  final Function(DownloadedVideoModel, int) onPreview;
  final Function(DownloadedVideoModel) onShare;
  final Function(String, DownloadedVideoModel, int) onMenu;

  const VideoCard({
    super.key,
    required this.video,
    required this.index,
    required this.onPreview,
    required this.onShare,
    required this.onMenu,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => widget.onPreview(widget.video, widget.index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面区域
              _buildCover(context),

              // 信息区域
              Padding(
                padding: const EdgeInsets.all(12),
                child: VideoInfo(
                  video: widget.video,
                  onShare: () => widget.onShare(widget.video),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建封面区域
  Widget _buildCover(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 缩略图
          VideoThumbnail(video: widget.video),

          // 渐变遮罩 - 让文字更清晰
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // 顶部标签栏
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                const Spacer(),
                // 更多菜单
                MoreMenuButton(
                  onSelected: (action) => widget.onMenu(action, widget.video, widget.index),
                ),
              ],
            ),
          ),

          // 时长标签
          if (widget.video.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: DurationLabel(duration: widget.video.durationFormatted),
            ),

          // 播放图标提示
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
