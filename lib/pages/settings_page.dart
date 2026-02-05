import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:calculator_app/services/biometric_service.dart';
import 'package:calculator_app/widgets/app_background.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = true;
  bool _isDeviceSupported = false;
  bool _canCheckBiometrics = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  // 缓存相关
  int _cacheSize = 0;
  bool _isCalculatingCache = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheSize();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final isSupported = await _biometricService.isDeviceSupported();
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final availableBiometrics = await _biometricService.getAvailableBiometrics();

    setState(() {
      _isDeviceSupported = isSupported;
      _canCheckBiometrics = canCheck;
      _isBiometricEnabled = isEnabled;
      _availableBiometrics = availableBiometrics;
      _isLoading = false;
    });
  }

  /// 计算缓存大小
  Future<void> _loadCacheSize() async {
    setState(() => _isCalculatingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(tempDir.path);

      if (await cacheDir.exists()) {
        _cacheSize = await _calculateCacheSize(cacheDir);
      }
    } catch (e) {
      _cacheSize = 0;
    }
    setState(() => _isCalculatingCache = false);
  }

  /// 计算目录大小
  Future<int> _calculateCacheSize(Directory dir) async {
    int totalSize = 0;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      // 忽略无权限的文件
    }

    return totalSize;
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 清理缓存
  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(tempDir.path);

      if (await cacheDir.exists()) {
        await _deleteDirectory(cacheDir);
      }

      // 重新计算缓存
      await _loadCacheSize();

      Get.snackbar(
        '成功',
        '缓存已清理',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '清理缓存失败: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isClearingCache = false);
    }
  }

  /// 递归删除目录
  Future<void> _deleteDirectory(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final success = await _biometricService.authenticate(
        localizedReason: '请验证身份以启用生物识别',
      );

      if (success) {
        await _biometricService.setBiometricEnabled(true);
        await _biometricService.setBiometricSetup(true);
        setState(() => _isBiometricEnabled = true);
        _showSnackBar('生物识别已启用', isSuccess: true);
      } else {
        _showSnackBar('验证失败，未启用生物识别');
      }
    } else {
      final success = await _biometricService.authenticate(
        localizedReason: '请验证身份以禁用生物识别',
      );

      if (success) {
        await _biometricService.setBiometricEnabled(false);
        setState(() => _isBiometricEnabled = false);
        _showSnackBar('生物识别已禁用', isSuccess: true);
      } else {
        _showSnackBar('验证失败');
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: isSuccess ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
  }

  String _getBiometricTypeName() {
    if (_availableBiometrics.isEmpty) return '生物识别';

    final type = _availableBiometrics.first;
    return _biometricService.getBiometricTypeName(type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 自定义 AppBar
            _buildAppBar(),

            // 内容区域
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SafeArea(
                      bottom: false,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 生物识别卡片
                                  _buildBiometricCard(),
                                  const SizedBox(height: 16),
                                  // 缓存管理卡片
                                  _buildCacheCard(),
                                  const SizedBox(height: 16),
                                  // 安全提示
                                  _buildSecurityTip(),
                                  const SizedBox(height: 24),
                                  // 应用信息
                                  _buildAppInfo(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建自定义AppBar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建缓存管理卡片
  Widget _buildCacheCard() {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: _isCalculatingCache
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : const Icon(
                        Icons.storage_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '缓存管理',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isCalculatingCache
                          ? '正在计算缓存大小...'
                          : '缓存占用: ${_formatFileSize(_cacheSize)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 清理按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isClearingCache ? null : _clearCache,
                  icon: _isClearingCache
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : const Icon(Icons.cleaning_services_rounded, size: 20),
                  label: Text(
                    _isClearingCache ? '清理中...' : '清理缓存',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isBiometricEnabled
                      ? Colors.green.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isBiometricEnabled
                        ? Colors.green.withOpacity(0.5)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getBiometricIcon(),
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '生物识别登录',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBiometricEnabled
                          ? '已启用 $_getBiometricTypeName() 快速登录'
                          : '启用 $_getBiometricTypeName() 以快速登录',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 可用的生物识别类型
          if (_canCheckBiometrics && _availableBiometrics.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _availableBiometrics.map((type) {
                return Chip(
                  avatar: const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green,
                  ),
                  label: Text(
                    _biometricService.getBiometricTypeName(type),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                );
              }).toList(),
            ),

          // 状态提示
          if (!_isDeviceSupported) ...[
            const SizedBox(height: 16),
            _buildStatusCard(
              icon: Icons.block,
              title: '设备不支持',
              message: '您的设备不支持生物识别功能',
              color: Colors.red,
            ),
          ] else if (!_canCheckBiometrics) ...[
            const SizedBox(height: 16),
            _buildStatusCard(
              icon: Icons.info_outline,
              title: '未设置生物识别',
              message: '请在系统设置中添加指纹或面部识别',
              color: Colors.orange,
            ),
          ] else if (_isBiometricEnabled) ...[
            const SizedBox(height: 16),
            _buildStatusCard(
              icon: Icons.check_circle,
              title: '已启用',
              message: '下次启动应用时将自动进行 $_getBiometricTypeName() 验证',
              color: Colors.green,
            ),
          ],

          const SizedBox(height: 20),

          // 开关按钮
          if (_isDeviceSupported && _canCheckBiometrics)
            Row(
              children: [
                const Spacer(),
                Switch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                  activeColor: Colors.green,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ClipRect(
              child: Align(
                heightFactor: value,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip() {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.white.withOpacity(0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '安全说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 生物识别数据仅存储在您的设备本地\n'
            '• 启用后，每次启动应用都需要验证\n'
            '• 可以随时在设置中关闭此功能',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return AppGlassCard(
      child: ListTile(
        leading: Icon(
          Icons.info,
          color: Colors.white.withOpacity(0.9),
        ),
        title: const Text(
          '关于应用',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Calculator App v1.0.0',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.7),
        ),
        onTap: () {
          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('关于'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calculator App'),
                  SizedBox(height: 8),
                  Text('版本: 1.0.0'),
                  SizedBox(height: 8),
                  Text('这是一个集成了多种功能的工具箱应用。'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    }
    return Icons.lock;
  }
}
