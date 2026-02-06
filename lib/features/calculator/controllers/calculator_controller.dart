import 'package:get/get.dart';

class CalculatorController extends GetxController {
  // Button labels
  static const String clearBtn = 'C';
  static const String signBtn = '±';
  static const String percentBtn = '%';
  static const String divideBtn = '÷';
  static const String multiplyBtn = '×';
  static const String subtractBtn = '-';
  static const String addBtn = '+';
  static const String equalsBtn = '=';
  static const String dotBtn = '.';

  // State variables
  String _display = '0';
  String _result = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  // Getters
  String get display => _display;
  String get result => _result;
  double? get firstOperand => _firstOperand;
  String? get operator => _operator;
  bool get shouldResetDisplay => _shouldResetDisplay;

  // Number input
  void onNumberPressed(String number) {
    if (_shouldResetDisplay) {
      _display = number;
      _shouldResetDisplay = false;
    } else {
      if (_display == '0' && number != dotBtn) {
        _display = number;
      } else if (number == dotBtn && _display.contains(dotBtn)) {
        return;
      } else {
        _display += number;
      }
    }
    update();
  }

  // Operator input
  void onOperatorPressed(String op) {
    if (_firstOperand == null) {
      _firstOperand = double.tryParse(_display);
    } else if (_operator != null && !_shouldResetDisplay) {
      calculateResult();
    }
    _operator = op;
    _shouldResetDisplay = true;
    update();
  }

  // Calculate result
  void calculateResult() {
    if (_firstOperand == null || _operator == null) return;

    final secondOperand = double.tryParse(_display);
    if (secondOperand == null) return;

    double calculatedResult;
    if (_operator == addBtn) {
      calculatedResult = _firstOperand! + secondOperand;
    } else if (_operator == subtractBtn) {
      calculatedResult = _firstOperand! - secondOperand;
    } else if (_operator == multiplyBtn) {
      calculatedResult = _firstOperand! * secondOperand;
    } else if (_operator == divideBtn) {
      if (secondOperand == 0) {
        _display = 'error'.tr;
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = true;
        update();
        return;
      }
      calculatedResult = _firstOperand! / secondOperand;
    } else {
      return;
    }

    // Format result to avoid floating point issues
    String formattedResult = calculatedResult.toStringAsFixed(10);
    if (formattedResult.contains('.')) {
      formattedResult = formattedResult.replaceAll(RegExp(r'0+$'), '');
      formattedResult = formattedResult.replaceAll(RegExp(r'\.$'), '');
    }

    _result = formattedResult;
    _display = formattedResult;
    _firstOperand = calculatedResult;
    _operator = null;
    _shouldResetDisplay = true;
    update();
  }

  // Clear all
  void onClearPressed() {
    _display = '0';
    _result = '';
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
    update();
  }

  // Toggle sign
  void onSignPressed() {
    final value = double.tryParse(_display);
    if (value != null) {
      _display = (-value).toString();
      if (_display.contains('.')) {
        _display = _display.replaceAll(RegExp(r'0+$'), '');
        _display = _display.replaceAll(RegExp(r'\.$'), '');
      }
      update();
    }
  }

  // Percentage
  void onPercentPressed() {
    final value = double.tryParse(_display);
    if (value != null) {
      _display = (value / 100).toString();
      if (_display.contains('.')) {
        _display = _display.replaceAll(RegExp(r'0+$'), '');
        _display = _display.replaceAll(RegExp(r'\.$'), '');
      }
      update();
    }
  }
}
