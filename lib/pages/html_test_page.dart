import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:calculator_app/utils/html_widget_factory.dart';

/// HTML Widget 测试页面
class HtmlTestPage extends StatefulWidget {
  const HtmlTestPage({super.key});

  @override
  State<HtmlTestPage> createState() => _HtmlTestPageState();
}

class _HtmlTestPageState extends State<HtmlTestPage> {
  final List<HtmlExample> _examples = [
    HtmlExample(
      title: '标题标签',
      html: '''
<h1>一级标题 H1</h1>
<h2>二级标题 H2</h2>
<h3>三级标题 H3</h3>
<h4>四级标题 H4</h4>
<h5>五级标题 H5</h5>
<h6>六级标题 H6</h6>
''',
    ),
    HtmlExample(
      title: '文本格式化',
      html: '''
<p>这是普通文本</p>
<p><strong>粗体文本</strong></p>
<p><em>斜体文本</em></p>
<p><u>下划线文本</u></p>
<p><s>删除线文本</s></p>
<p><mark>高亮文本</mark></p>
<p><small>小号文本</small></p>
<p><sub>下标</sub> 和 <sup>上标</sup></p>
<p><code>行内代码</code></p>
<p><kbd>键盘文本</kbd></p>
''',
    ),
    HtmlExample(
      title: '链接',
      html: '''
<p>这是一个链接: <a href="https://flutter.dev">Flutter 官网</a></p>
<p>邮箱链接: <a href="mailto:test@example.com">发送邮件</a></p>
<p>电话链接: <a href="tel:+1234567890">拨打电话</a></p>
''',
    ),
    HtmlExample(
      title: '列表',
      html: '''
<h3>无序列表</h3>
<ul>
  <li>苹果</li>
  <li>香蕉</li>
  <li>橙子</li>
</ul>

<h3>有序列表</h3>
<ol>
  <li>第一步</li>
  <li>第二步</li>
  <li>第三步</li>
</ol>
''',
    ),
    HtmlExample(
      title: '图片',
      html: '''
<h3>网络图片</h3>
<img src="https://picsum.photos/300/200" alt="随机图片" style="border-radius: 8px;" />

<h3>带链接的图片</h3>
<a href="https://flutter.dev">
  <img src="https://flutter.dev/assets/homepage/carousel/slide_1-bg-4e1f2f5edf6ea5b7b3c5f1d3e8f2e3f5f5e5d5c5b5a59999999_1920x720.jpg" alt="Flutter" style="width: 100%; border-radius: 8px;" />
</a>
''',
    ),
    HtmlExample(
      title: '表格',
      html: '''
<table style="width: 100%; border-collapse: collapse;">
  <thead>
    <tr style="background-color: #f2f2f2;">
      <th style="border: 1px solid #ddd; padding: 8px;">姓名</th>
      <th style="border: 1px solid #ddd; padding: 8px;">年龄</th>
      <th style="border: 1px solid #ddd; padding: 8px;">城市</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="border: 1px solid #ddd; padding: 8px;">张三</td>
      <td style="border: 1px solid #ddd; padding: 8px;">25</td>
      <td style="border: 1px solid #ddd; padding: 8px;">北京</td>
    </tr>
    <tr style="background-color: #f9f9f9;">
      <td style="border: 1px solid #ddd; padding: 8px;">李四</td>
      <td style="border: 1px solid #ddd; padding: 8px;">30</td>
      <td style="border: 1px solid #ddd; padding: 8px;">上海</td>
    </tr>
  </tbody>
</table>
''',
    ),
    HtmlExample(
      title: '块引用和代码块',
      html: '''
<h3>块引用</h3>
<blockquote>
  这是一段引用文本。引用通常用于表示引用其他来源的内容。
</blockquote>

<h3>嵌套引用</h3>
<blockquote>
  <p>这是一级引用</p>
  <blockquote>
    <p>这是二级引用</p>
  </blockquote>
</blockquote>

<h3>代码块</h3>
<pre><code>void main() {
  print('Hello, World!');
}</code></pre>
''',
    ),
    HtmlExample(
      title: '分割线和水平线',
      html: '''
<p>第一段内容</p>
<hr>
<p>第二段内容</p>
<hr style="border: 2px dashed #ccc;">
<p>第三段内容</p>
''',
    ),
    HtmlExample(
      title: '样式和颜色',
      html: '''
<p style="color: red;">红色文字</p>
<p style="color: blue; font-size: 18px;">蓝色大号文字</p>
<p style="background-color: yellow; padding: 8px;">黄色背景</p>
<p style="border: 2px solid green; padding: 8px; border-radius: 8px;">带边框的文字</p>
<p style="text-align: center;">居中对齐</p>
<p style="text-align: right;">右对齐</p>
''',
    ),
    HtmlExample(
      title: '嵌套内容',
      html: '''
<div style="background-color: #f0f0f0; padding: 16px; border-radius: 8px; margin: 8px 0;">
  <h4 style="color: #333; margin-top: 0;">卡片标题</h4>
  <p style="color: #666;">这是卡片内容，包含<strong>粗体</strong>、<em>斜体</em>和<a href="#">链接</a>。</p>
  <ul>
    <li>列表项 1</li>
    <li>列表项 2</li>
  </ul>
</div>
''',
    ),
    HtmlExample(
      title: '完整文章示例',
      html: '''
<h1 style="color: #2c3e50;">Flutter 学习指南</h1>
<p style="color: #7f8c8d; font-size: 14px;">发布于 2024年1月1日</p>
<hr style="margin: 16px 0;">

<h2 style="color: #34495e;">什么是 Flutter?</h2>
<p>Flutter 是 Google 推出的<strong>跨平台移动应用开发框架</strong>，可以快速构建高质量的 iOS 和 Android 应用。</p>

<h2 style="color: #34495e;">主要特性</h2>
<ul>
  <li><strong>跨平台</strong>：一套代码同时支持 iOS 和 Android</li>
  <li><strong>高性能</strong>：使用原生渲染，性能接近原生应用</li>
  <li><strong>热重载</strong>：开发效率高，修改代码后立即看到效果</li>
  <li><strong>丰富的组件</strong>：提供大量预置的 UI 组件</li>
</ul>

<h2 style="color: #34495e;">代码示例</h2>
<pre style="background-color: #f4f4f4; padding: 12px; border-radius: 4px; overflow-x: auto;"><code>import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Text('Hello World'),
    ),
  );
}</code></pre>

<blockquote style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 16px 0;">
  <strong>提示：</strong> 学习 Flutter 之前，建议先掌握 Dart 语言基础。
</blockquote>

<p>想了解更多信息，请访问 <a href="https://flutter.dev" style="color: #3498db;">Flutter 官方文档</a>。</p>
''',
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('HTML Widget 测试'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _examples.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(_examples[index].title),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // HTML 代码预览
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HTML 代码',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // 复制代码
                        Clipboard.setData(
                          ClipboardData(text: _examples[_selectedIndex].html),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已复制到剪贴板'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _examples[_selectedIndex].html.trim(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 分割线
          const Divider(height: 1),

          // 渲染结果
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '渲染效果',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: HtmlWidget(
                      _examples[_selectedIndex].html,
                      factoryBuilder: () => HtmlWidgetFactory(),
                      customWidgetBuilder: (element) {
                        // 可以在这里自定义某些标签的渲染
                        return null;
                      },
                      onErrorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.red[50],
                          child: Text(
                            '渲染错误: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
                      onTapUrl: (url) {
                        // 处理链接点击
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('点击链接: $url'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return true;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// HTML 示例数据类
class HtmlExample {
  final String title;
  final String html;

  HtmlExample({
    required this.title,
    required this.html,
  });
}
