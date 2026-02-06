import 'package:flutter/material.dart';
import 'package:calculator_app/widgets/app_background.dart';
import '../../controllers/video_download_controller.dart';

/// 支持的平台横幅
class PlatformBanner extends StatelessWidget {
  const PlatformBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.apps,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '支持的平台',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  PlatformChip(label: '抖音', icon: Icons.music_note),
                  PlatformChip(label: 'TikTok', icon: Icons.music_video),
                  PlatformChip(label: 'B站', icon: Icons.tv),
                  PlatformChip(label: '微博', icon: Icons.wechat),
                  PlatformChip(label: '快手', icon: Icons.video_library),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 平台芯片
class PlatformChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const PlatformChip({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
        ],
      ),
    );
  }
}
