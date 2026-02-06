import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calculator_app/features/calculator/controllers/calculator_controller.dart';

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('calculator'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Display area
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              color: Colors.grey[100],
              child: GetBuilder<CalculatorController>(
                init: CalculatorController(),
                builder: (controller) => Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (controller.result.isNotEmpty && controller.operator != null)
                      Text(
                        '${controller.firstOperand} ${controller.operator}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    Text(
                      controller.display,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Buttons
          Expanded(
            flex: 5,
            child: GetBuilder<CalculatorController>(
              builder: (controller) => Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildButtonRow(context, controller, [
                      CalculatorController.clearBtn,
                      CalculatorController.signBtn,
                      CalculatorController.percentBtn,
                      CalculatorController.divideBtn
                    ]),
                    const SizedBox(height: 8),
                    _buildButtonRow(context, controller, ['7', '8', '9', CalculatorController.multiplyBtn]),
                    const SizedBox(height: 8),
                    _buildButtonRow(context, controller, ['4', '5', '6', CalculatorController.subtractBtn]),
                    const SizedBox(height: 8),
                    _buildButtonRow(context, controller, ['1', '2', '3', CalculatorController.addBtn]),
                    const SizedBox(height: 8),
                    _buildButtonRow(context, controller, ['0', CalculatorController.dotBtn, CalculatorController.equalsBtn]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context, CalculatorController controller, List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) {
          final isOperator = [
            CalculatorController.divideBtn,
            CalculatorController.multiplyBtn,
            CalculatorController.subtractBtn,
            CalculatorController.addBtn,
            CalculatorController.equalsBtn
          ].contains(button);
          final isSpecial = [
            CalculatorController.clearBtn,
            CalculatorController.signBtn,
            CalculatorController.percentBtn
          ].contains(button);
          final isZero = button == '0';

          return Expanded(
            flex: isZero ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildButton(context, controller, button, isOperator, isSpecial),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    CalculatorController controller,
    String label,
    bool isOperator,
    bool isSpecial,
  ) {
    return ElevatedButton(
      onPressed: () {
        if (label == CalculatorController.clearBtn) {
          controller.onClearPressed();
        } else if (label == CalculatorController.signBtn) {
          controller.onSignPressed();
        } else if (label == CalculatorController.percentBtn) {
          controller.onPercentPressed();
        } else if (label == CalculatorController.equalsBtn) {
          controller.calculateResult();
        } else if ([
          CalculatorController.addBtn,
          CalculatorController.subtractBtn,
          CalculatorController.multiplyBtn,
          CalculatorController.divideBtn
        ].contains(label)) {
          controller.onOperatorPressed(label);
        } else {
          controller.onNumberPressed(label);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isOperator
            ? Theme.of(context).colorScheme.primary
            : isSpecial
                ? Colors.grey[300]
                : Colors.white,
        foregroundColor: isOperator ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: isOperator ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
