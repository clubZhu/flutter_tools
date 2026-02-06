import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/video_download_controller.dart';

/// 解析按钮
class ParseButton extends StatelessWidget {
  const ParseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoDownloadController>();

    return Obx(() {
      final isParsing = controller.isParsing.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isParsing
                ? [
                    Colors.blue.shade300,
                    Colors.cyan.shade200,
                  ]
                : [
                    Colors.blue.shade400,
                    Colors.cyan.shade300,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(isParsing ? 0.2 : 0.4),
              blurRadius: isParsing ? 10 : 20,
              offset: const Offset(0, 8),
              spreadRadius: isParsing ? 0 : 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isParsing ? null : controller.parseVideoUrl,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              child: Center(
                child: isParsing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '解析中...',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '解析视频',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
