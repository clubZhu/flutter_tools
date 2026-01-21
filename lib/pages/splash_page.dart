import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:calculator_app/services/biometric_service.dart';
import 'package:calculator_app/routes/app_routes.dart';

/// 启动页 - 生物识别验证
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = true;
  bool _canCheckBiometrics = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  String _statusMessage = '初始化中...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 检查设备是否支持生物识别
    final isSupported = await _biometricService.isDeviceSupported();
    if (!isSupported) {
      setState(() {
        _isLoading = false;
        _statusMessage = '设备不支持生物识别';
      });
      // 延迟后跳转到主页
      await Future.delayed(const Duration(seconds: 2));
      _navigateToHome();
      return;
    }

    // 检查是否可以检查生物识别
    final canCheck = await _biometricService.canCheckBiometrics();
    if (!canCheck) {
      setState(() {
        _isLoading = false;
        _statusMessage = '未设置生物识别';
      });
      await Future.delayed(const Duration(seconds: 2));
      _navigateToHome();
      return;
    }

    // 获取可用的生物识别类型
    final availableBiometrics = await _biometricService.getAvailableBiometrics();

    // 检查是否启用了生物识别
    final isEnabled = await _biometricService.isBiometricEnabled();

    setState(() {
      _isLoading = false;
      _canCheckBiometrics = true;
      _availableBiometrics = availableBiometrics;
      _isBiometricEnabled = isEnabled;
      _statusMessage = _getBiometricTypeName(availableBiometrics);
    });

    // 如果启用了生物识别，自动触发认证
    if (isEnabled && availableBiometrics.isNotEmpty) {
      await _performBiometricAuth();
    } else {
      // 未启用，延迟后跳转到主页
      await Future.delayed(const Duration(seconds: 1));
      _navigateToHome();
    }
  }

  Future<void> _performBiometricAuth() async {
    final success = await _biometricService.authenticate(
      localizedReason: '请使用${_getBiometricTypeName(_availableBiometrics)}解锁应用',
    );

    if (success) {
      _navigateToHome();
    } else {
      // 认证失败，显示重试按钮
      setState(() {
        _statusMessage = '认证失败';
      });
    }
  }

  String _getBiometricTypeName(List<BiometricType> types) {
    if (types.isEmpty) return '生物识别';

    final type = types.first;
    return _biometricService.getBiometricTypeName(type);
  }

  void _navigateToHome() {
    Get.offAllNamed(AppRoutes.INITIAL);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 或图标
                Icon(
                  _getBiometricIcon(),
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),

                // 应用名称
                Text(
                  'Calculator App',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 48),

                // 状态消息
                if (_isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在检查生物识别...'),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (_canCheckBiometrics &&
                          _availableBiometrics.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _isBiometricEnabled
                              ? '已启用生物识别登录'
                              : '可在设置中启用生物识别',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // 认证按钮
                      if (_canCheckBiometrics &&
                          _availableBiometrics.isNotEmpty &&
                          !_isLoading)
                        ElevatedButton.icon(
                          onPressed: _performBiometricAuth,
                          icon: Icon(_getBiometricIconData()),
                          label: const Text('点击验证身份'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),

                      // 跳过按钮
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _navigateToHome,
                        child: const Text('跳过'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIconData() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    }
    return Icons.lock;
  }

  IconData _getBiometricIcon() {
    return _getBiometricIconData();
  }
}
