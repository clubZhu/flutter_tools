import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:calculator_app/routes/app_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // 布局模式：true 为网格，false 为饼状
  bool _isGridMode = false; // 默认显示饼状图
  late AnimationController _switchController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController; // 脉冲动画控制器
  final GlobalKey _pieChartKey = GlobalKey();

  // 功能列表数据
  final List<FeatureItem> _features = [
    FeatureItem(
      icon: Icons.download,
      title: '视频下载',
      color: Colors.teal,
      onTap: () => AppNavigation.goToVideoDownload(),
    ),
    FeatureItem(
      icon: Icons.videocam,
      title: '录制视频',
      color: Colors.red,
      isHighlight: true,
      onTap: () => AppNavigation.goToVideoRecording(),
    ),
    FeatureItem(
      icon: Icons.cloud_upload,
      title: '文件传输',
      color: Colors.indigo,
      onTap: () => AppNavigation.goToWebService(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _switchController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _switchController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _switchController,
        curve: Curves.elasticOut,
      ),
    );

    // 脉冲动画控制器 - 用于饼状图边缘动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(); // 循环播放

    _switchController.forward();
  }

  @override
  void dispose() {
    _switchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _switchLayout() {
    setState(() {
      _isGridMode = !_isGridMode;
    });
    _switchController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade400,
              Colors.blue.shade400,
              Colors.cyan.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 自定义 AppBar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          // 布局切换按钮
                          _buildLayoutSwitchButton(),
                          const SizedBox(width: 12),
                          _buildLayoutSettingButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 快速统计卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap:(){
                            AppNavigation.goToVideoDownloaded();
                          },
                          child: _buildStatCard(
                            icon: Icons.video_library,
                            title: '下载历史',
                            subtitle: '视频下载历史',
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap:(){
                            AppNavigation.goToVideoHistory();
                          },
                          child: _buildStatCard(
                            icon: Icons.history,
                            title: '拍摄相册',
                            subtitle: '视频录制历史',
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 功能展示区域
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: _buildLayoutContent(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建布局内容（带动画）
  Widget _buildLayoutContent() {
    return AnimatedBuilder(
      animation: _switchController,
      builder: (context, child) {
        final content = _isGridMode ? _buildGridLayout() : _buildPieLayout();

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: content,
          ),
        );
      },
    );
  }
  Widget _buildLayoutSettingButton() {
    return GestureDetector(
      onTap:(){
        AppNavigation.goToSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: child,
                );
              },
              child: const Icon(
                 Icons.settings,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// 构建布局切换按钮
  Widget _buildLayoutSwitchButton() {
    return GestureDetector(
      onTap: _switchLayout,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: child,
                );
              },
              child: Icon(
                _isGridMode ?  Icons.pie_chart: Icons.grid_view,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建网格布局
  Widget _buildGridLayout() {
    return GridView.builder(
      key: const ValueKey('grid_layout'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        return _buildFeatureCard(_features[index]);
      },
    );
  }

  /// 构建饼状布局（可点击）
  Widget _buildPieLayout() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          key: const ValueKey('pie_layout'),
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  key: _pieChartKey,
                  onTapDown: (details) {
                    final RenderBox? box = _pieChartKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box == null) return;

                    final localPosition = box.globalToLocal(details.globalPosition);
                    final size = box.size;
                    final center = Offset(size.width / 2, size.height / 2);
                    final dx = localPosition.dx - center.dx;
                    final dy = localPosition.dy - center.dy;
                    final angle = math.atan2(dy, dx);

                    // 找到点击的扇形
                    final clickedIndex = _getTappedSliceIndex(angle);
                    if (clickedIndex >= 0 && clickedIndex < _features.length) {
                      _features[clickedIndex].onTap();
                    }
                  },
                  child: SizedBox(
                    height: 300,
                    child: CustomPaint(
                      painter: PieChartPainter(
                        _features,
                        animationValue: _pulseController.value,
                      ),
                      size: const Size.square(300),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 根据点击角度获取扇形索引
  int _getTappedSliceIndex(double angle) {
    // 将角度标准化到 [0, 2π) 范围
    var normalizedAngle = angle + math.pi / 2;
    if (normalizedAngle < 0) {
      normalizedAngle += 2 * math.pi;
    }

    final sliceAngle = 2 * math.pi / _features.length;
    final index = (normalizedAngle / sliceAngle).floor();
    return index.clamp(0, _features.length - 1);
  }

  /// 构建统计卡片
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建功能卡片
  Widget _buildFeatureCard(FeatureItem feature) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            // 半透明玻璃效果
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: feature.isHighlight
                ? [
                    // 高亮项的发光效果
                    BoxShadow(
                      color: feature.color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    // 普通项的阴影
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    feature.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 饼图绘制器
class PieChartPainter extends CustomPainter {
  final List<FeatureItem> features;
  final double animationValue;

  PieChartPainter(
    this.features, {
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    double startAngle = -math.pi / 2;
    const totalAngle = 2 * math.pi;
    final sliceAngle = totalAngle / features.length;

    // 计算脉冲动画的缩放因子 (0.0 ~ 1.0)
    final pulseValue = (math.sin(animationValue * 2 * math.pi) + 1) / 2;
    final glowRadius = 3.0 + pulseValue * 5.0; // 光晕半径从3到8变化
    final glowOpacity = 0.3 + pulseValue * 0.4; // 透明度从0.3到0.7变化

    for (int i = 0; i < features.length; i++) {
      final sweepAngle = sliceAngle;
      final path = Path()..moveTo(center.dx, center.dy);

      // 绘制扇形
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();

      // 绘制渐变填充
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          features[i].color.withOpacity(0.7),
          features[i].color.withOpacity(0.9),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // 绘制边框（带动画效果）
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // 绘制边缘发光效果（脉冲动画）
      final glowPaint = Paint()
        ..color = features[i].color.withOpacity(glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowRadius
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, glowPaint);

      // 绘制图标（在扇形中心位置）
      _drawIconOnSlice(canvas, center, radius, startAngle, sweepAngle, features[i]);

      startAngle += sweepAngle;
    }
  }

  void _drawIconOnSlice(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    FeatureItem feature,
  ) {
    // 计算图标位置（在扇形中间）
    final midAngle = startAngle + sweepAngle / 2;
    final iconRadius = radius * 0.65;
    final iconX = center.dx + iconRadius * math.cos(midAngle);
    final iconY = center.dy + iconRadius * math.sin(midAngle);

    // 绘制白色圆形背景
    final iconBackgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(iconX, iconY), 24, iconBackgroundPaint);

    // 使用 TextPainter 绘制图标
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(feature.icon.codePoint),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontFamily: 'MaterialIcons',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(iconX - textPainter.width / 2, iconY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! PieChartPainter) return true;
    return oldDelegate.features != features ||
        oldDelegate.animationValue != animationValue;
  }
}

/// 功能项数据类
class FeatureItem {
  final IconData icon;
  final String title;
  final Color color;
  final bool isHighlight;
  final VoidCallback onTap;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.color,
    this.isHighlight = false,
    required this.onTap,
  });
}
