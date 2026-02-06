import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/routes/app_routes.dart';
import 'package:calculator_app/routes/custom_transitions.dart';
import 'package:calculator_app/features/splash/pages/splash_page.dart';
import 'package:calculator_app/features/home/pages/home_page.dart';
import 'package:calculator_app/features/calculator/pages/calculator_page.dart';
import 'package:calculator_app/features/chat/pages/chat_page.dart';
import 'package:calculator_app/features/html_test/pages/html_test_page.dart';
import 'package:calculator_app/features/settings/pages/settings_page.dart';
import 'package:calculator_app/features/video_download/pages/video_download_page.dart';
import 'package:calculator_app/features/video_download/pages/video_downloaded_page.dart';
import 'package:calculator_app/features/video_download/controllers/video_downloaded_controller.dart';
import 'package:calculator_app/features/web_service/pages/web_service_page.dart';
import 'package:calculator_app/features/video_recording/pages/video_recording_page.dart';
import 'package:calculator_app/features/common_video_preview/pages/common_video_preview_page.dart';
import 'package:calculator_app/features/video_history/pages/video_history_page.dart';
import 'package:calculator_app/features/video_recording/controllers/video_recording_controller.dart';

/// 路由页面配置
class AppPages {
  static final routes = [
    // 启动页 - 淡入动画
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // 首页 - 淡入缩放动画
    CustomTransitions.customFadeZoom(
      page: GetPage(
        name: AppRoutes.INITIAL,
        page: () => const HomePage(),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),

    // 计算器 - 从右侧滑入
    CustomTransitions.customSlideFade(
      page: GetPage(
        name: AppRoutes.CALCULATOR,
        page: () => const CalculatorPage(),
      ),
      duration: const Duration(milliseconds: 300),
    ),

    // 聊天页面 - 从底部滑入
    CustomTransitions.customBottomSlideFade(
      page: GetPage(
        name: AppRoutes.CHAT,
        page: () => const ChatPage(),
      ),
      duration: const Duration(milliseconds: 350),
    ),


    // HTML测试 - 淡入缩放
    CustomTransitions.customFadeZoom(
      page: GetPage(
        name: AppRoutes.HTML_TEST,
        page: () => const HtmlTestPage(),
      ),
      duration: const Duration(milliseconds: 300),
    ),

    // 设置页面 - 从右侧滑入
    CustomTransitions.customSlideFade(
      page: GetPage(
        name: AppRoutes.SETTINGS,
        page: () => const SettingsPage(),
      ),
      duration: const Duration(milliseconds: 300),
    ),

    // 视频下载页面 - 从底部滑入（模态页面风格）
    CustomTransitions.customBottomSlideFade(
      page: GetPage(
        name: AppRoutes.VIDEO_DOWNLOAD,
        page: () => const VideoDownloadPage(),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),

    // 视频已下载页面 - 从右侧滑入
    CustomTransitions.customSlideFade(
      page: GetPage(
        name: AppRoutes.VIDEO_DOWNLOADED,
        page: () => const VideoDownloadedPage(),
        binding: BindingsBuilder(() {
          Get.lazyPut<VideoDownloadedController>(() => VideoDownloadedController());
        }),
      ),
      duration: const Duration(milliseconds: 300),
    ),

    // WebService文件传输 - 从底部滑入
    CustomTransitions.customBottomSlideFade(
      page: GetPage(
        name: AppRoutes.WEB_SERVICE,
        page: () => const WebServicePage(),
      ),
      duration: const Duration(milliseconds: 350),
    ),

    // 视频录制页面 - 淡入缩放（突出重点功能）
    CustomTransitions.customFadeZoom(
      page: GetPage(
        name: AppRoutes.VIDEO_RECORDING,
        page: () => const VideoRecordingPage(),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),

    // 视频预览页面 - 从底部滑入（全屏播放）
    CustomTransitions.customBottomSlideFade(
      page: GetPage(
        name: AppRoutes.VIDEO_PREVIEW,
        page: () => const CommonVideoPreviewPage(),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ),

    // 视频历史页面 - 从右侧滑入
    CustomTransitions.customSlideFade(
      page: GetPage(
        name: AppRoutes.VIDEO_HISTORY,
        page: () => const VideoHistoryPage(),
        binding: BindingsBuilder(() {
          Get.lazyPut<VideoRecordingController>(() => VideoRecordingController());
        }),
      ),
      duration: const Duration(milliseconds: 300),
    ),
  ];
}
