import 'package:flutter/material.dart';

final List<Map<String, dynamic>> checkout_food = [
  {
    'name': 'Random Food',
    'imageUrl': 'assets/images/restaurant1.png',
    'price': 173.0,
    'quantity': 4,
  },
  {
    'name': 'Spicy Wings',
    'imageUrl': 'assets/images/restaurant1.png',
    'price': 250.0,
    'quantity': 2,
  },
  {
    'name': 'Spicy Wings',
    'imageUrl': 'assets/images/restaurant1.png',
    'price': 250.0,
    'quantity': 2,
  },
  {
    'name': 'Spicy Wings',
    'imageUrl': 'assets/images/restaurant1.png',
    'price': 250.0,
    'quantity': 2,
  },
];

class FoodItemCheckout extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  const FoodItemCheckout({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // Remove shadow
      color: Colors.white, // Set background color to white
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageUrl,
                width: 100,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱$price',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'x$quantity',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 82, 80, 80),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
