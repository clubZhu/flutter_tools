import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
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
  bool _isSetup = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final isSupported = await _biometricService.isDeviceSupported();
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final isSetup = await _biometricService.isBiometricSetup();
    final availableBiometrics = await _biometricService.getAvailableBiometrics();

    setState(() {
      _isDeviceSupported = isSupported;
      _canCheckBiometrics = canCheck;
      _isBiometricEnabled = isEnabled;
      _isSetup = isSetup;
      _availableBiometrics = availableBiometrics;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // 启用生物识别，先进行验证
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
      // 禁用生物识别，需要验证
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
            SizedBox(height: 20,),
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
                    Text(
                      '生物识别登录',
                      style: const TextStyle(
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
                  avatar: Icon(
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
    return Container(
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
                  style: TextStyle(
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
              Text(
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
