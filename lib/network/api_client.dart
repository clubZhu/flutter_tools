import 'package:dio/dio.dart';
import 'package:calculator_app/network/dio_client.dart';
import 'package:calculator_app/network/api_exception.dart';
import 'package:calculator_app/network/api_response.dart';

/// API 客户端单例
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();

  factory ApiClient() => _instance;

  late final DioClient _dioClient;

  /// 初始化
  static void init({
    String baseUrl = 'https://api.example.com',
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Map<String, String>? headers,
  }) {
    _instance._dioClient = DioClient(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
    );
  }

  /// GET 请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response, null);
    } on ApiException {
      rethrow;
    }
  }

  /// POST 请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response, null);
    } on ApiException {
      rethrow;
    }
  }

  /// PUT 请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response, null);
    } on ApiException {
      rethrow;
    }
  }

  /// DELETE 请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response, null);
    } on ApiException {
      rethrow;
    }
  }

  /// PATCH 请求
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response, null);
    } on ApiException {
      rethrow;
    }
  }

  /// 下载文件
  Future<void> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _dioClient.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
      );
    } on ApiException {
      rethrow;
    }
  }

  /// 获取 Dio 实例（用于特殊场景，如上传文件）
  DioClient get dioClient => _dioClient;
}

/// API 服务基类
abstract class BaseApiService {
  /// 获取 API 客户端
  ApiClient get api => ApiClient();
}

/// 示例：具体的 API 服务
class CommonApiService extends BaseApiService {
  /// 示例：登录
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) async {
    return await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  /// 示例：获取用户信息
  Future<ApiResponse<Map<String, dynamic>>> getUserInfo(
      {required String userId}) async {
    return await api.get<Map<String, dynamic>>(
      '/user/$userId',
    );
  }

  /// 示例：获取列表数据
  Future<ApiResponse<List<dynamic>>> getItemList({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await api.get<List<dynamic>>(
      '/items',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
  }
}
