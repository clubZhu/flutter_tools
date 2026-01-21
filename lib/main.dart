import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/routes/app_pages.dart';
import 'package:calculator_app/routes/app_routes.dart';
import 'package:calculator_app/translations/app_translations.dart';
import 'package:calculator_app/network/api_client.dart';

void main() {
  // 初始化 API 客户端
  ApiClient.init(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'app_title'.tr,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      locale: const Locale('zh', 'CN'), // Default language
      fallbackLocale: const Locale('en', 'US'), // Fallback language
      translations: AppTranslations(),
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
    );
  }
}
