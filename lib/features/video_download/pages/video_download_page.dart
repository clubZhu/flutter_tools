import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/widgets/app_background.dart';
import 'package:calculator_app/features/video_download/controllers/video_download_controller.dart';
import 'package:calculator_app/features/video_download/pages/widgets/app_bar.dart';
import 'package:calculator_app/features/video_download/pages/widgets/platform_banner.dart';
import 'package:calculator_app/features/video_download/pages/widgets/url_input_section.dart';
import 'package:calculator_app/features/video_download/pages/widgets/parse_button.dart';
import 'package:calculator_app/features/video_download/pages/widgets/error_message.dart';
import 'package:calculator_app/features/video_download/pages/widgets/video_info_section.dart';
import 'package:calculator_app/features/video_download/pages/widgets/video_preview_section.dart';
import 'package:calculator_app/features/video_download/pages/widgets/download_section.dart';
import 'package:calculator_app/features/video_download/pages/widgets/downloaded_images_section.dart';

/// 视频下载页面
class VideoDownloadPage extends StatelessWidget {
  const VideoDownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化或获取控制器
    final controller = Get.put(VideoDownloadController());

    return Scaffold(
      body: AppBackground(
        child: FadeTransition(
          opacity: controller.fadeAnimation,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 自定义 AppBar
              const VideoDownloadAppBar(),

              // 内容区域
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 支持的平台提示
                        const PlatformBanner(),
                        const SizedBox(height: 24),

                        // URL 输入区域
                        const UrlInputSection(),
                        const SizedBox(height: 24),

                        // 解析按钮
                        const ParseButton(),

                        // 错误信息
                        const ErrorMessage(),

                        // 视频信息展示
                        Obx(() => controller.videoInfo.value != null
                            ? Column(
                                children: [
                                  const SizedBox(height: 32),
                                  ScaleTransition(
                                    scale: controller.scaleAnimation,
                                    child: const Column(
                                      children: [
                                        VideoInfoSection(),
                                        SizedBox(height: 24),
                                        VideoPreviewSection(),
                                        SizedBox(height: 24),
                                        DownloadSection(),
                                        DownloadedImagesSection(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
