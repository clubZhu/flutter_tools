import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 生物识别服务
class BiometricService {
  BiometricService._();

  static final BiometricService _instance = BiometricService._();

  factory BiometricService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 存储键
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricSetupKey = 'biometric_setup';

  /// 检查设备是否支持生物识别
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      return isSupported;
    } catch (e) {
      print('检查设备支持失败: $e');
      return false;
    }
  }

  /// 检查是否设置了生物识别
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      print('检查生物识别能力失败: $e');
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('获取可用生物识别失败: $e');
      return [];
    }
  }

  /// 执行生物识别认证
  Future<bool> authenticate({
    String localizedReason = '请进行身份验证',
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      print('生物识别认证失败: ${e.message}');
      return false;
    } catch (e) {
      print('生物识别认证错误: $e');
      return false;
    }
  }

  /// 停止认证
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('停止认证失败: $e');
    }
  }

  /// 检查是否已启用生物识别
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('检查生物识别启用状态失败: $e');
      return false;
    }
  }

  /// 设置生物识别启用状态
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      print('设置生物识别启用状态失败: $e');
      return false;
    }
  }

  /// 检查是否已完成生物识别设置
  Future<bool> isBiometricSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricSetupKey) ?? false;
    } catch (e) {
      print('检查生物识别设置状态失败: $e');
      return false;
    }
  }

  /// 标记生物识别设置完成
  Future<bool> setBiometricSetup(bool setup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_biometricSetupKey, setup);
    } catch (e) {
      print('设置生物识别设置状态失败: $e');
      return false;
    }
  }

  /// 获取生物识别类型名称
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return '指纹';
      case BiometricType.face:
        return '面部识别';
      case BiometricType.iris:
        return '虹膜识别';
      default:
        return '生物识别';
    }
  }

  /// 清除所有生物识别设置
  Future<bool> clearBiometricSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_biometricSetupKey);
      return true;
    } catch (e) {
      print('清除生物识别设置失败: $e');
      return false;
    }
  }

  /// 检查是否可以使用生物识别（支持 + 已设置 + 已启用）
  Future<bool> canUseBiometric() async {
    try {
      final isSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();
      final isEnabled = await isBiometricEnabled();

      return isSupported && canCheck && isEnabled;
    } catch (e) {
      print('检查生物识别可用性失败: $e');
      return false;
    }
  }
}
