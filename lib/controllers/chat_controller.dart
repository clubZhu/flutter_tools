import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/models/chat_message.dart';

class ChatController extends GetxController {
  // Reactive state
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxString inputText = ''.obs;
  final RxBool isRecording = false.obs;
  final ScrollController scrollController = ScrollController();

  // Getters
  List<ChatMessage> get messageList => messages;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // Initialize with welcome message
  void _initializeChat() {
    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'chat_welcome_message'.tr,
        isUser: false,
        options: [
          'chat_option_credit_card'.tr,
          'chat_option_debit_card'.tr,
          'chat_option_savings_card'.tr,
        ],
        disclaimer: 'chat_ai_disclaimer'.tr,
      ),
    );
    _scrollToBottom();
  }

  // Send text message
  void sendMessage() {
    if (inputText.value.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: inputText.value.trim(),
      isUser: true,
    );

    messages.add(userMessage);
    inputText.value = '';
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      _generateAIResponse(userMessage.content);
    });
  }

  // Select option from list
  void selectOption(String option) {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: option,
      isUser: true,
    );

    messages.add(userMessage);
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      _generateAIResponse(option);
    });
  }

  // Generate AI response based on user input
  void _generateAIResponse(String userInput) {
    String aiResponse = '';
    List<String>? options;
    String? disclaimer = 'chat_ai_disclaimer'.tr;

    if (userInput.contains('信用卡') || userInput.contains('Credit')) {
      aiResponse = 'chat_credit_card_response'.tr;
      options = ['chat_option_apply'.tr, 'chat_option_details'.tr, 'chat_option_requirements'.tr];
    } else if (userInput.contains('储蓄卡') || userInput.contains('Savings')) {
      aiResponse = 'chat_savings_card_response'.tr;
      options = ['chat_option_open_account'.tr, 'chat_option_interest_rate'.tr];
    } else if (userInput.contains('借记卡') || userInput.contains('Debit')) {
      aiResponse = 'chat_debit_card_response'.tr;
      options = ['chat_option_apply'.tr, 'chat_option_features'.tr];
    } else if (userInput.contains('办卡')) {
      aiResponse = 'chat_what_card_question'.tr;
      options = [
        'chat_option_credit_card'.tr,
        'chat_option_debit_card'.tr,
        'chat_option_savings_card'.tr,
      ];
    } else {
      aiResponse = 'chat_default_response'.tr;
    }

    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        options: options,
        disclaimer: disclaimer,
      ),
    );
    _scrollToBottom();
  }

  // Toggle recording state
  void toggleRecording() {
    isRecording.value = !isRecording.value;
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Clear chat history
  void clearChat() {
    messages.clear();
    _initializeChat();
  }
}
