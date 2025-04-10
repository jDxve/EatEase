// orderstatus_indecator.dart
import 'package:flutter/material.dart';

class OrderStatusIndicator extends StatelessWidget {
  final int currentStatus;

  const OrderStatusIndicator({
    Key? key,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildStep(
                Icons.pending_actions,
                "Pending Order",
                stepNumber: 1,
              ),
              _buildConnection(2),
              _buildStep(
                Icons.restaurant,
                "Preparing",
                stepNumber: 2,
              ),
              _buildConnection(3),
              _buildStep(
                Icons.delivery_dining,
                "Ready for Pickup",
                stepNumber: 3,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusText(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String label, {required int stepNumber}) {
    final bool isActive = currentStatus >= stepNumber;
    final Color stepColor = isActive ? Colors.red : Colors.grey[400]!;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stepColor,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.red : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnection(int step) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: step <= currentStatus ? Colors.red : Colors.grey[400],
    );
  }

  String _getStatusText() {
    switch (currentStatus) {
      case 1:
        return "Your order is pending confirmation";
      case 2:
        return "Your order is being prepared";
      case 3:
        return "Your order is ready for pickup";
      default:
        return "Unknown status";
    }
  }
}
