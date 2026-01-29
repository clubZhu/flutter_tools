import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:calculator_app/services/biometric_service.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade400,
        title: const Text(
          '设置',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
    );
  }

  Widget _buildBiometricCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isBiometricEnabled 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getBiometricIcon(),
                    size: 32,
                    color: _isBiometricEnabled 
                        ? Colors.green 
                        : Colors.grey[600],
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isBiometricEnabled
                            ? '已启用$_getBiometricTypeName()快速登录'
                            : '启用$_getBiometricTypeName()以快速登录',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.1),
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
                message: '下次启动应用时将自动进行$_getBiometricTypeName()验证',
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.deepPurple.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '安全说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
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
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          Icons.info,
          color: Colors.deepPurple.shade400,
        ),
        title: const Text(
          '关于应用',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Calculator App v1.0.0'),
        trailing: const Icon(Icons.chevron_right),
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
