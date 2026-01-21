/// API 统一响应格式
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final bool success;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.success,
  });

  /// 从 JSON 创建
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? json['status'] as int? ?? 0,
      message: json['message'] as String? ?? json['msg'] as String? ?? '',
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'],
      success: (json['code'] as int? ?? json['status'] as int? ?? 0) == 200 ||
              (json['success'] as bool? ?? false) ==
                  true,
    );
  }

  /// 成功响应
  factory ApiResponse.success(T data, {String message = '请求成功'}) {
    return ApiResponse<T>(
      code: 200,
      message: message,
      data: data,
      success: true,
    );
  }

  /// 失败响应
  factory ApiResponse.error(
    String message, {
    int code = 500,
    T? data,
  }) {
    return ApiResponse<T>(
      code: code,
      message: message,
      data: data,
      success: false,
    );
  }

  /// 是否成功
  bool get isSuccess => success && code == 200;

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'data': data,
      'success': success,
    };
  }

  @override
  String toString() {
    return 'ApiResponse{code: $code, message: $message, success: $success, data: $data}';
  }
}
