class HtmlContentTypeChecker {
  static final RegExp _inlineCardPattern = RegExp(r'data-card-id\s*=', caseSensitive: false);
  static final RegExp _htmlTagPattern = RegExp(r'<[^>]*>|&[^;]+;');

  // 检查项配置
  static final List<_CheckItem> _checkItems = [
    _CheckItem('heading', r'<h[1-6][^>]*>'),
    _CheckItem('image', r'<img[^>]*>|<image[^>]*>'),
    _CheckItem('table', r'<table[^>]*>'),
    _CheckItem('list', r'<(ul|ol)[^>]*>'),
    _CheckItem('code', r'<pre[^>]*>|<code[^>]*>'),
    _CheckItem('quote', r'<blockquote[^>]*>'),
  ];

  /// 主判断方法是否包含多个HTML标签
  static bool hasMultipleTypes(String htmlContent) {
    // 基础检查
    if (htmlContent.isEmpty) return false;
    if (!htmlContent.contains('<')) return false;
    if (htmlContent.contains('data-card-id')) return false;

    // 统计找到的类型
    int typeCount = 0;

    // 按配置顺序检查
    for (final item in _checkItems) {
      if (item.pattern.hasMatch(htmlContent)) {
        typeCount++;
        // 如果已经有至少一种类型，检查是否有文本
        if (typeCount >= 1) {
          if (_hasTextFast(htmlContent)) {
            return true; // 找到文本+至少一种其他类型
          }
        }
        // 如果找到两种类型（不需要文本）
        if (typeCount >= 2) {
          // 即使没有文本，如果有两种非文本类型也算多类型
          return true;
        }
      }
    }
    return typeCount > 1;
  }

  /// 快速文本检查（用于提前退出）
  static bool _hasTextFast(String content) {
    // 采样检查：取内容的中间部分
    final length = content.length;
    if (length < 50) {
      // 短内容直接检查
      final text = content.replaceAll(_htmlTagPattern, ' ').trim();
      return text.isNotEmpty;
    }

    // 长内容采样
    final start = length ~/ 3;
    final end = start + 100; // 检查100个字符
    final sample =
        content.substring(start.clamp(0, length), end.clamp(0, length));

    final text = sample.replaceAll(_htmlTagPattern, ' ').trim();
    return text.isNotEmpty;
  }

}

/// 检查项配置类
class _CheckItem {
  final String type;
  final RegExp pattern;

  _CheckItem(this.type, String patternStr)
      : pattern = RegExp(patternStr, caseSensitive: false);
}
