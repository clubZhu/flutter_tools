import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/widgets/app_background.dart';
import '../../controllers/video_download_controller.dart';

/// 错误信息组件
class ErrorMessage extends StatelessWidget {
  const ErrorMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadController>();

    return Obx(() {
      final error = controller.errorMessage.value;
      if (error == null) return const SizedBox.shrink();

      return AppGlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (error!.contains('抖音')) ...[
              const SizedBox(height: 8),
              const Text(
                '💡 抖音链接解析提示：',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '• 确保链接是从抖音App最新复制的\n'
                '• 尝试在抖音App中分享到微信后再复制\n'
                '• 短链接可能展开失败，建议使用完整链接\n'
                '• 检查网络连接是否正常\n'
                '• 如果仍然失败，可能是API服务暂时不可用',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
