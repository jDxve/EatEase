import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class FoodItemCard extends StatefulWidget {
  final Map<String, dynamic> foodItem;
  final Function(int) onQuantityChanged;
  final Function onDelete; // Function to handle deletion
  final String userId;

  const FoodItemCard({
    Key? key,
    required this.foodItem,
    required this.onQuantityChanged,
    required this.onDelete,
    required this.userId,
  }) : super(key: key);

  @override
  _FoodItemCardState createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.foodItem['quantity'] ?? 1;
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
    widget.onQuantityChanged(quantity);
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
      widget.onQuantityChanged(quantity);
    } else {
      // Call delete function if quantity is 1
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodItem = widget.foodItem;
    double price = (foodItem['price'] as num?)?.toDouble() ?? 0.0;
    double totalPrice = price * quantity;

    return Card(
      color: Colors.pink[50],
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                foodItem['imageUrl'],
                height: 60,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        foodItem['name'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        height: 28,
                        width: 85,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: _decrementQuantity,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: quantity > 1
                                    ? const Icon(
                                        Icons.remove,
                                        color: Color.fromARGB(255, 219, 6, 6),
                                        size: 14,
                                      )
                                    : const Icon(
                                        Icons.delete,
                                        color: Color.fromARGB(255, 219, 6, 6),
                                        size: 14,
                                      ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _incrementQuantity,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currencyFormat.format(price)}',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 96, 95, 95),
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(totalPrice)}',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
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
