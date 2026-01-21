import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

/// API 拦截器
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // 请求拦截
    print('======== 请求开始 ========');
    print('请求方法: ${options.method}');
    print('请求地址: ${options.uri}');
    print('请求头: ${options.headers}');
    if (options.data != null) {
      print('请求参数: ${options.data}');
    }
    if (options.queryParameters != null) {
      print('Query参数: ${options.queryParameters}');
    }

    // 添加 Token（如果有）
    _addToken(options);

    // 添加通用请求头
    _addCommonHeaders(options);

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // 响应拦截
    print('======== 响应返回 ========');
    print('响应地址: ${response.requestOptions.uri}');
    print('响应状态码: ${response.statusCode}');
    print('响应数据: ${response.data}');

    // 可以在这里处理通用响应逻辑
    _handleResponse(response);

    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // 错误拦截
    print('======== 请求错误 ========');
    print('错误地址: ${err.requestOptions.uri}');
    print('错误类型: ${err.type}');
    print('错误信息: ${err.message}');
    if (err.response != null) {
      print('错误状态码: ${err.response?.statusCode}');
      print('错误数据: ${err.response?.data}');
    }

    // 处理特定错误
    _handleError(err);

    return handler.next(err);
  }

  /// 添加 Token
  void _addToken(RequestOptions options) {
    // 从存储中获取 Token
    // final token = StorageService.getToken();
    final token = _getStoredToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('已添加Token: Bearer ${token.substring(0, 10)}...');
    }
  }

  /// 获取存储的 Token（可替换为实际的存储逻辑）
  String? _getStoredToken() {
    // TODO: 从实际存储中获取 Token
    // return SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));
    return null;
  }

  /// 添加通用请求头
  void _addCommonHeaders(RequestOptions options) {
    // 可以在这里添加通用的请求头
    // options.headers['X-Request-ID'] = Uuid().v4();
    // options.headers['X-App-Version'] = '1.0.0';
  }

  /// 处理响应
  void _handleResponse(Response response) {
    // 可以在这里处理通用响应逻辑
    // 例如：处理业务状态码、刷新 Token 等

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'] ?? data['status'];
      final message = data['message'] ?? data['msg'];

      // 处理业务层面的错误
      if (code != null && code != 200 && code != 0) {
        print('业务错误: [$code] $message');
      }
    }
  }

  /// 处理错误
  void _handleError(DioException err) {
    // 处理 401 未授权
    if (err.response?.statusCode == 401) {
      _handleUnauthorized();
      return;
    }

    // 处理 403 禁止访问
    if (err.response?.statusCode == 403) {
      _handleForbidden();
      return;
    }

    // 处理网络错误
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      print('网络超时，请检查网络连接');
    }

    if (err.type == DioExceptionType.connectionError) {
      print('网络连接失败，请检查网络设置');
    }
  }

  /// 处理未授权错误
  void _handleUnauthorized() {
    print('Token 已过期，需要重新登录');

    // 清除 Token
    // StorageService.clearToken();

    // 跳转到登录页面
    // Get.offAllNamed(AppRoutes.LOGIN);

    // 显示提示
    _showErrorSnackbar('登录已过期，请重新登录');
  }

  /// 处理禁止访问错误
  void _handleForbidden() {
    print('没有权限访问该资源');
    _showErrorSnackbar('没有权限访问');
  }

  /// 显示错误提示
  void _showErrorSnackbar(String message) {
    getx.Get.snackbar(
      '提示',
      message,
      snackPosition: getx.SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}

/// 日志拦截器（更详细的日志）
class DetailedLogInterceptor extends Interceptor {
  final bool request;
  final bool error;
  final bool response;

  DetailedLogInterceptor({
    this.request = true,
    this.error = true,
    this.response = true,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (request) {
      print('┌─────────────── 请求 ───────────────');
      print('│ method: ${options.method}');
      print('│ url: ${options.uri}');
      print('│ headers: ${options.headers}');
      if (options.data != null) {
        print('│ data: ${options.data}');
      }
      if (options.queryParameters != null) {
        print('│ query: ${options.queryParameters}');
      }
      print('└───────────────────────────────────');
    }
    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (this.response) {
      print('┌─────────────── 响应 ───────────────');
      print('│ url: ${response.requestOptions.uri}');
      print('│ statusCode: ${response.statusCode}');
      print('│ data: ${response.data}');
      print('└───────────────────────────────────');
    }
    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (this.error) {
      print('┌─────────────── 错误 ───────────────');
      print('│ url: ${err.requestOptions.uri}');
      print('│ type: ${err.type}');
      print('│ message: ${err.message}');
      if (err.response != null) {
        print('│ statusCode: ${err.response?.statusCode}');
        print('│ data: ${err.response?.data}');
      }
      print('└───────────────────────────────────');
    }
    return handler.next(err);
  }
}
