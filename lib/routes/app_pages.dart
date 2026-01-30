import 'package:get/get.dart';
import 'package:calculator_app/routes/app_routes.dart';
import 'package:calculator_app/pages/splash_page.dart';
import 'package:calculator_app/pages/home_page.dart';
import 'package:calculator_app/pages/calculator_page.dart';
import 'package:calculator_app/pages/chat_page.dart';
import 'package:calculator_app/pages/item_list_page.dart';
import 'package:calculator_app/pages/html_test_page.dart';
import 'package:calculator_app/pages/settings_page.dart';
import 'package:calculator_app/pages/video_download_page.dart';
import 'package:calculator_app/features/video_download/pages/video_downloaded_page.dart';
import 'package:calculator_app/pages/web_service_page.dart';
import 'package:calculator_app/pages/video_recording_page.dart';
import 'package:calculator_app/pages/video_preview_page.dart';
import 'package:calculator_app/pages/video_history_page.dart';
import 'package:calculator_app/controllers/video_recording_controller.dart';

/// 路由页面配置
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.INITIAL,
      page: () => const HomePage(),
    ),
    GetPage(
      name: AppRoutes.CALCULATOR,
      page: () => const CalculatorPage(),
    ),
    GetPage(
      name: AppRoutes.CHAT,
      page: () => const ChatPage(),
    ),
    GetPage(
      name: AppRoutes.ITEM_LIST,
      page: () => const ItemListPage(),
    ),
    GetPage(
      name: AppRoutes.HTML_TEST,
      page: () => const HtmlTestPage(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsPage(),
    ),
    GetPage(
      name: AppRoutes.VIDEO_DOWNLOAD,
      page: () => const VideoDownloadPage(),
    ),
    GetPage(
      name: AppRoutes.VIDEO_DOWNLOADED,
      page: () => const VideoDownloadedPage(),
    ),
    GetPage(
      name: AppRoutes.WEB_SERVICE,
      page: () => const WebServicePage(),
    ),
    GetPage(
      name: AppRoutes.VIDEO_RECORDING,
      page: () => VideoRecordingPage(),
    ),
    GetPage(
      name: AppRoutes.VIDEO_PREVIEW,
      page: () => const VideoPreviewPage(),
    ),
    GetPage(
      name: AppRoutes.VIDEO_HISTORY,
      page: () => const VideoHistoryPage(),
      binding: BindingsBuilder(() => {
        Get.lazyPut<VideoRecordingController>(() => VideoRecordingController()),
      }),
    ),
  ];
}
