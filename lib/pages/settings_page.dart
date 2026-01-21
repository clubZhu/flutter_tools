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
        _showSnackBar('生物识别已启用');
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
        _showSnackBar('生物识别已禁用');
      } else {
        _showSnackBar('验证失败');
      }
    }
  }

  void _showSnackBar(String message) {
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 生物识别设置部分
                _buildSection(
                  title: '安全设置',
                  children: [
                    if (!_isDeviceSupported)
                      _buildTile(
                        icon: Icons.block,
                        title: '设备不支持生物识别',
                        subtitle: '您的设备不支持生物识别功能',
                        trailing: null,
                      )
                    else if (!_canCheckBiometrics)
                      _buildTile(
                        icon: Icons.info_outline,
                        title: '未设置生物识别',
                        subtitle: '请在系统设置中添加指纹或面部识别',
                        trailing: null,
                      )
                    else
                      SwitchListTile(
                        secondary: Icon(
                          _getBiometricIcon(),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text('$_getBiometricTypeName()登录'),
                        subtitle: Text(
                          _isBiometricEnabled
                              ? '已启用$_getBiometricTypeName()快速登录'
                              : '启用$_getBiometricTypeName()以快速登录',
                        ),
                        value: _isBiometricEnabled,
                        onChanged: _toggleBiometric,
                      ),

                    // 可用的生物识别类型
                    if (_canCheckBiometrics && _availableBiometrics.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Wrap(
                          spacing: 8,
                          children: _availableBiometrics.map((type) {
                            return Chip(
                              avatar: const Icon(Icons.check_circle, size: 18),
                              label: Text(
                                _biometricService.getBiometricTypeName(type),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),

                // 其他设置（可扩展）
                _buildSection(
                  title: '其他',
                  children: [
                    _buildTile(
                      icon: Icons.info,
                      title: '关于',
                      subtitle: '应用版本 1.0.0',
                      onTap: () {
                        Get.snackbar(
                          '关于',
                          'Calculator App v1.0.0',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
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
