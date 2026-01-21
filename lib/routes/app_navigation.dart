import 'package:get/get.dart';
import 'package:calculator_app/routes/app_routes.dart';

/// 路由导航工具类
class AppNavigation {
  AppNavigation._();

  /// 跳转到首页
  static void goToHome() {
    Get.offAllNamed(AppRoutes.INITIAL);
  }

  /// 跳转到计算器页面
  static void goToCalculator() {
    Get.toNamed(AppRoutes.CALCULATOR);
  }

  /// 跳转到聊天页面
  static void goToChat() {
    Get.toNamed(AppRoutes.CHAT);
  }

  /// 跳转到列表页面
  static void goToList() {
    Get.toNamed(AppRoutes.ITEM_LIST);
  }

  /// 跳转到 HTML 测试页面
  static void goToHtmlTest() {
    Get.toNamed(AppRoutes.HTML_TEST);
  }

  /// 跳转到设置页面
  static void goToSettings() {
    Get.toNamed(AppRoutes.SETTINGS);
  }

  /// 跳转到视频下载页面
  static void goToVideoDownload() {
    Get.toNamed(AppRoutes.VIDEO_DOWNLOAD);
  }

  /// 跳转到 WebService 文件传输页面
  static void goToWebService() {
    Get.toNamed(AppRoutes.WEB_SERVICE);
  }

  /// 跳转到视频录制页面
  static void goToVideoRecording() {
    Get.toNamed(AppRoutes.VIDEO_RECORDING);
  }

  /// 跳转到视频历史页面
  static void goToVideoHistory() {
    Get.toNamed(AppRoutes.VIDEO_HISTORY);
  }

  /// 返回上一页
  static void goBack<T>([T? result]) {
    Get.back(result: result);
  }

  /// 通用跳转方法
  static void toNamed(String route, {dynamic arguments}) {
    Get.toNamed(route, arguments: arguments);
  }

  /// 替换当前页面
  static void offNamed(String route, {dynamic arguments}) {
    Get.offNamed(route, arguments: arguments);
  }

  /// 清空栈并跳转
  static void offAllNamed(String route, {dynamic arguments}) {
    Get.offAllNamed(route, arguments: arguments);
  }
}
