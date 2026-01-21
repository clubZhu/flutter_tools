import 'package:calculator_app/network/api_client.dart';
import 'package:calculator_app/network/api_exception.dart';
import 'package:calculator_app/network/api_response.dart';

/// 网络请求使用示例
class ApiExample {
  final _apiService = CommonApiService();

  /// 示例1：简单的 GET 请求
  Future<void> example1_GetRequest() async {
    try {
      final response = await _apiService.getUserInfo(userId: '123');
      if (response.isSuccess) {
        print('数据: ${response.data}');
      } else {
        print('错误: ${response.message}');
      }
    } on ApiException catch (e) {
      print('API 异常: $e');
    } catch (e) {
      print('未知错误: $e');
    }
  }

  /// 示例2：POST 请求
  Future<void> example2_PostRequest() async {
    try {
      final response = await _apiService.login(
        username: 'admin',
        password: '123456',
      );
      if (response.isSuccess) {
        print('登录成功: ${response.data}');
      }
    } on ApiException catch (e) {
      print('登录失败: ${e.message}');
    }
  }

  /// 示例3：获取列表数据
  Future<void> example3_GetList() async {
    try {
      final response = await _apiService.getItemList(
        page: 1,
        pageSize: 20,
      );
      if (response.isSuccess) {
        final list = response.data;
        print('列表数据: $list');
      }
    } on ApiException catch (e) {
      print('加载失败: ${e.message}');
    }
  }

  /// 示例4：直接使用 ApiClient
  Future<void> example4_DirectUse() async {
    final api = ApiClient();

    try {
      // GET 请求
      final getResponse = await api.get<Map<String, dynamic>>(
        '/user/profile',
        queryParameters: {'id': '123'},
      );

      // POST 请求
      final postResponse = await api.post<Map<String, dynamic>>(
        '/user/create',
        data: {
          'name': '张三',
          'age': 25,
        },
      );

      // PUT 请求
      final putResponse = await api.put<Map<String, dynamic>>(
        '/user/update',
        data: {
          'id': '123',
          'name': '李四',
        },
      );

      // DELETE 请求
      final deleteResponse = await api.delete<Map<String, dynamic>>(
        '/user/delete',
        queryParameters: {'id': '123'},
      );
    } on ApiException catch (e) {
      print('请求失败: ${e.message}');
    }
  }

  /// 示例5：创建自定义 API 服务
  Future<void> example5_CustomService() async {
    // 使用
    final userService = UserService();
    try {
      final response = await userService.getUserProfile('123');
      if (response.isSuccess) {
        print('用户信息: ${response.data}');
      }
    } on ApiException catch (e) {
      print('错误: ${e.message}');
    }
  }
}

/// 示例：自定义 API 服务（继承 BaseApiService）
class UserService extends BaseApiService {
  Future<ApiResponse<Map>> getUserProfile(String id) async {
    return await api.get<Map>('/user/$id');
  }

  Future<ApiResponse<List>> getUserList({int page = 1}) async {
    return await api.get<List>('/users', queryParameters: {'page': page});
  }

  Future<ApiResponse> updateUser(Map<String, dynamic> data) async {
    return await api.put('/user/update', data: data);
  }
}
