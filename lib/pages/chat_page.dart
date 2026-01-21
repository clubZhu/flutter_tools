import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/controllers/chat_controller.dart';
import 'package:calculator_app/models/chat_message.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Chat content
            Expanded(
              child: GetBuilder<ChatController>(
                init: ChatController(),
                builder: (controller) => Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Chat header
                      _buildChatHeader(),

                      // Messages list
                      Expanded(
                        child: ListView.builder(
                          controller: controller.scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.messageList.length,
                          itemBuilder: (context, index) {
                            final message = controller.messageList[index];
                            return _buildMessageBubble(context, controller, message);
                          },
                        ),
                      ),

                      // Input area
                      _buildInputArea(controller),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top header with status
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          Text(
            'chat_title'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40), // Balance with back button
        ],
      ),
    );
  }

  // Chat header with AI info
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFF1A73E8),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'chat_ai_name'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                Text(
                  'chat_ai_title'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Help and close icons
          Icon(Icons.help_outline, color: Colors.grey[600]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.close, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Message bubble
  Widget _buildMessageBubble(
    BuildContext context,
    ChatController controller,
    ChatMessage message,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFFE8EAF6)
                  : const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),

          // Options (for AI messages)
          if (!message.isUser && message.options != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: message.options!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return InkWell(
                    onTap: () => controller.selectOption(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${index + 1}. $option',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Disclaimer (for AI messages)
          if (!message.isUser && message.disclaimer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    message.disclaimer!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.content_copy, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_full, size: 14, color: Colors.grey[600]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Input area
  Widget _buildInputArea(ChatController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Input bar
          Row(
            children: [
              // Microphone button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF5F6368)),
                  onPressed: controller.toggleRecording,
                ),
              ),
              const SizedBox(width: 8),

              // Text field
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onChanged: (value) => controller.inputText.value = value,
                    onSubmitted: (_) => controller.sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'chat_input_placeholder'.tr,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Clock button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.access_time, color: Color(0xFF5F6368)),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // Floating voice button
          const SizedBox(height: 8),
          GestureDetector(
            onTap: controller.toggleRecording,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A73E8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
