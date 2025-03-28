import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;

  const StepIndicator({Key? key, required this.currentStep}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildStep(Icons.restaurant_menu, stepNumber: 1),
          _buildConnection(2),
          _buildStep(Icons.shopping_cart, stepNumber: 2),
          _buildConnection(3),
          _buildStep(Icons.payment, stepNumber: 3),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, {required int stepNumber}) {
    final bool isActive = currentStep == stepNumber;
    final Color stepColor = stepNumber == 1 || isActive ? Colors.red : Colors.grey[400]!;

    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stepColor,
      ),
      child: Center(
        child: Icon(
          icon,
          color:Colors.white,
          size: 17,
        ),
      ),
    );
  }

  Widget _buildConnection(int step) {
    return Expanded(
      child: Container(
        height: 2,
        color: step <= currentStep ? Colors.red : Colors.grey[400],
      ),
    );
  }
}