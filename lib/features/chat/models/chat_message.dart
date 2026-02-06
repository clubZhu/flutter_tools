/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final List<String>? options;
  final String? disclaimer;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.options,
    this.disclaimer,
  });
}
