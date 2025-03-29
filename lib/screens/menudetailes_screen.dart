import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eatease/screens/mycart_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class MenudetailesScreen extends StatefulWidget {
  final String foodId;
  final String title;
  final String imageUrl;
  final double price;
  final String description;
  final String userId;
  final String restaurantId; // Ensure restaurantId is included
  final String categoryName;

  const MenudetailesScreen({
    Key? key,
    required this.foodId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.userId,
    required this.restaurantId, // Add restaurantId to constructor
    required this.categoryName,
  }) : super(key: key);

  @override
  _MenudetailesScreenState createState() => _MenudetailesScreenState();
}

class _MenudetailesScreenState extends State<MenudetailesScreen> {
  int quantity = 1; // Set default quantity to 1
  Map<String, int> cartQuantities =
      {}; // To keep track of quantities in the cart

  void _increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _addToCart() async {
    // Check if the item is already in the cart
    if (cartQuantities.containsKey(widget.foodId)) {
      _showCircularNotification(
          "Item is already in the cart.", Colors.redAccent);
      return;
    }

    final orderItem = {
      "menu_id": widget.foodId,
      "name": widget.title,
      "quantity": quantity,
      "price": widget.price,
    };

    // Create the order payload
    final orderPayload = {
      "customer_id": widget.userId,
      "restaurant_id": widget.restaurantId,
      "order_id": null,
      "items": [orderItem],
      "order_status": 1,
      "order_stage": "add to cart",
      "pickup_time": DateTime.now().toIso8601String(),
      // Removed order_id generation from client side
    };

    // Log the order payload for debugging
    print("Order Payload: $orderPayload");

    // Send the POST request to create the order
    final response = await http.post(
      Uri.parse("${dotenv.env['API_BASE_URL']}/orders"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode(orderPayload),
    );

    // Check the response status
    if (response.statusCode == 200) {
      // If the item was added successfully, update the cart quantities
      cartQuantities[widget.foodId] =
          (cartQuantities[widget.foodId] ?? 0) + quantity;

      // Show a success notification
      _showCircularNotification("Item added to cart!", Colors.green);
    } else if (response.statusCode == 400) {
      // If the server returns a warning about existing items
      final responseBody = json.decode(response.body);
      if (responseBody['error'] != null) {
        _showCircularNotification(responseBody['error'], Colors.orange);
      }
    } else {
      // Handle other response statuses
      _showCircularNotification("Failed to add item to cart.", Colors.red);
    }
  }

  void _showCircularNotification(String message, Color backgroundColor) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60, // Adjust this value to position the notification
        left: MediaQuery.of(context).size.width * 0.1, // Center horizontally
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 10,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry);

    // Remove the notification after a delay
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: GestureDetector(
                    onTap: () {
                      final userId = widget.userId;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyCartScreen(
                            userId: userId,
                            restaurantId:
                                widget.restaurantId, // Pass restaurantId here
                          ),
                        ),
                      );
                    },
                    child:
                        Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    currencyFormat.format(widget.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.categoryName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 28,
                  width: 85,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _decreaseQuantity,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Color.fromARGB(255, 219, 6, 6),
                            size: 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _increaseQuantity,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color.fromARGB(255, 219, 6, 6),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: _addToCart,
                            child: Text(
                              'Add to Cart (${currencyFormat.format(widget.price * (cartQuantities[widget.foodId] ?? 0 + quantity))})',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
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
}
