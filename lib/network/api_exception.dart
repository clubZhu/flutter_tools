import 'dart:io';
import 'package:dio/dio.dart';

/// API 异常类
class ApiException implements Exception {
  final String message;
  final int? code;

  ApiException(this.message, [this.code]);

  @override
  String toString() => 'ApiException: $message (code: $code)';

  /// 从 Dio 异常创建
  factory ApiException.fromDioError(DioException error) {
    String message;
    int? code;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时';
        code = 408;
        break;
      case DioExceptionType.sendTimeout:
        message = '发送超时';
        code = 408;
        break;
      case DioExceptionType.receiveTimeout:
        message = '接收超时';
        code = 408;
        break;
      case DioExceptionType.badResponse:
        code = error.response?.statusCode;
        message = _getMessageFromStatusCode(code);
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        code = 499;
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          message = '网络连接失败';
        } else {
          message = error.message ?? '未知错误';
        }
        code = null;
        break;
      default:
        message = error.message ?? '未知错误';
        code = null;
    }

    return ApiException(message, code);
  }

  /// 从状态码获取错误信息
  static String _getMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '拒绝访问';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 422:
        return '验证失败';
      case 429:
        return '请求过于频繁';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      case 504:
        return '网关超时';
      default:
        return '请求失败 (错误码: $statusCode)';
    }
  }
}
