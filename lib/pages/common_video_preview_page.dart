import 'package:flutter/material.dart';

import 'common_video_preview/common_video_preview_widget.dart';

/// 通用视频预览页面
/// 支持已下载视频和录制视频的预览
/// 支持横屏播放和双指缩放
class CommonVideoPreviewPage extends StatelessWidget {
  const CommonVideoPreviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CommonVideoPreviewWidget();
  }
}
