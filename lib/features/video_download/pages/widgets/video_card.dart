import 'package:flutter/material.dart';
import '../../models/downloaded_video_model.dart';
import 'video_thumbnail.dart';
import 'video_info.dart';
import 'video_labels.dart';
import 'video_menu_button.dart';

/// 优化的视频卡片组件 - 使用 AutomaticKeepAliveClientMixin 保持状态
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
  State<VideoCard> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 封面区域
          Hero(
            tag: 'video_cover_${widget.video.id}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onPreview(widget.video, widget.index),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // 封面图 - 使用优化的缩略图加载
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoThumbnail(video: widget.video),
                      ),

                      // 时长标签
                      if (widget.video.duration != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: DurationLabel(duration: widget.video.durationFormatted),
                        ),

                      // 平台标签
                      Positioned(
                        top: 8,
                        left: 8,
                        child: PlatformChip(name: widget.video.platformName),
                      ),

                      // 更多菜单
                      Positioned(
                        top: 8,
                        right: 8,
                        child: MoreMenuButton(
                          onSelected: (action) => widget.onMenu(action, widget.video, widget.index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 信息区域
          VideoInfo(
            video: widget.video,
            onShare: () => widget.onShare(widget.video),
          ),
        ],
      ),
    );
  }
}
