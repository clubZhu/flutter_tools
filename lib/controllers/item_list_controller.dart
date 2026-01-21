import 'package:get/get.dart';
import 'package:calculator_app/models/item_model.dart';

/// 列表页面控制器
class ItemListController extends GetxController {
  // 列表数据
  final RxList<ItemModel> items = <ItemModel>[].obs;

  // 是否正在加载
  final RxBool isLoading = false.obs;

  // 是否还有更多数据
  final RxBool hasMore = true.obs;

  // 当前页码
  int _currentPage = 1;

  // 每页数量
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  /// 加载数据
  Future<void> loadItems({bool isRefresh = false}) async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      // 模拟网络请求延迟
      await Future.delayed(const Duration(seconds: 1));

      // 生成模拟数据
      final newItems = _generateMockItems(
        isRefresh ? 1 : _currentPage,
        isRefresh ? _pageSize : 10,
      );

      if (isRefresh) {
        items.clear();
        items.addAll(newItems);
        _currentPage = 1;
      } else {
        items.addAll(newItems);
        _currentPage++;
      }

      // 判断是否还有更多数据
      hasMore.value = items.length < 100; // 假设最多100条
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载数据失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadItems(isRefresh: true);
  }

  /// 加载更多
  Future<void> onLoadMore() async {
    if (!isLoading.value && hasMore.value) {
      await loadItems();
    }
  }

  /// 删除项目
  void deleteItem(String id) {
    items.removeWhere((item) => item.id == id);
    Get.snackbar(
      '成功',
      '已删除',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// 生成模拟数据
  List<ItemModel> _generateMockItems(int page, int count) {
    final List<ItemModel> mockItems = [];
    for (int i = 0; i < count; i++) {
      final index = (page - 1) * _pageSize + i + 1;
      mockItems.add(ItemModel(
        id: 'item_$index',
        title: '项目 $index',
        description: '这是项目 $index 的详细描述信息，可以包含更多内容。',
        imageUrl: 'https://picsum.photos/200/200?random=$index',
        createdAt: DateTime.now().subtract(Duration(days: index)),
      ));
    }
    return mockItems;
  }
}
