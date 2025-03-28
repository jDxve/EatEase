import 'package:flutter/material.dart';
import 'package:eatease/components/fooditem_card.dart';
import 'package:eatease/screens/checkout_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:eatease/components/step_indicator.dart';

final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class MyCartScreen extends StatefulWidget {
  final String? userId;
  final String restaurantId;

  const MyCartScreen({
    super.key,
    this.userId,
    required this.restaurantId,
  });

  @override
  _MyCartScreenState createState() => _MyCartScreenState();
}

class _MyCartScreenState extends State<MyCartScreen> {
  Map<String, dynamic>? order;
  bool isLoading = true;
  double totalAmount = 0.0;
  final int currentStep = 2;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (widget.userId != null) {
      final fetchedOrder = await fetchOrder(widget.userId!);
      setState(() {
        order = fetchedOrder;
        isLoading = false;
        totalAmount = _calculateTotalAmount();
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> fetchOrder(String customerId) async {
    try {
      final response = await http
          .get(Uri.parse('${dotenv.env['API_BASE_URL']}/orders/$customerId'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['order'];
      } else {
        print('Failed to load order: ${response.body}');
      }
    } catch (e) {
      print('Error fetching order: $e');
    }
    return null;
  }

  double _calculateTotalAmount() {
    if (order == null || order!['items'].isEmpty) return 0.0;
    return order!['items'].fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/orders/${widget.userId}/items/$itemId'),
      );

      if (response.statusCode == 200) {
        print("Item deleted successfully");
        setState(() {
          order!['items'].removeWhere((item) => item['id'] == itemId);
          totalAmount = _calculateTotalAmount();
        });
      } else {
        print('Failed to delete item: ${response.body}');
      }
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  Future<void> _updateItemQuantity(String itemId, int newQuantity) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/orders/${widget.userId}/items/$itemId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        print('Item quantity updated successfully');
        // Optionally, you can update the local order state if needed
        setState(() {
          // Update the total amount after successful update
          totalAmount = _calculateTotalAmount();
        });
      } else {
        print('Failed to update item quantity: ${response.body}');
      }
    } catch (e) {
      print('Error updating item quantity: $e');
    }
  }

  void _checkout() async {
    if (order == null || order!['items'].isEmpty) {
      print('No items in the cart to checkout.');
      return;
    }

    final orderData = {
      'order_stage': 'order checkout',
      'items': order!['items'].map((item) {
        return {
          'id': item['id'],
          'quantity': item['quantity'],
        };
      }).toList(),
    };

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_BASE_URL']}/orders/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        print('Order stage updated successfully');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              userId: widget.userId,
              restaurantId: widget.restaurantId,
            ),
          ),
        );
      } else {
        print('Failed to update order stage: ${response.body}');
      }
    } catch (e) {
      print('Error during checkout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: Center(
                    child: const Text(
                      'My Cart',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : order == null || order!['items'].isEmpty
                        ? Center(child: Text('No items in the cart.'))
                        : Column(
                            children: [
                              StepIndicator(currentStep: currentStep),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Orders',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: order!['items'].length,
                                  itemBuilder: (context, index) {
                                    final item = order!['items'][index];
                                    return FoodItemCard(
                                      foodItem: {
                                        'name': item['name'] ?? 'Unknown',
                                        'imageUrl':
                                            'assets/images/restaurant1.png',
                                        'price': item['price'] ?? 0.0,
                                        'quantity': item['quantity'] ?? 1,
                                        'customer_id': widget.userId ?? '',
                                        '_id': item['id'] ?? '',
                                      },
                                      onQuantityChanged: (newQuantity) {
                                        setState(() {
                                          item['quantity'] = newQuantity;
                                          totalAmount = _calculateTotalAmount();
                                        });
                                        _updateItemQuantity(item['id'],
                                            newQuantity); // Update quantity on the server
                                      },
                                      onDelete: () {
                                        _deleteItem(item['id'] ?? '');
                                      },
                                      userId: widget.userId ?? '',
                                    );
                                  },
                                ),
                              ),
                              const Divider(thickness: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    _buildSummaryRow(
                                      'Total Payment',
                                      '${currencyFormat.format(totalAmount)}',
                                      isBold: true,
                                    ),
                                    const SizedBox(height: 50),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        onPressed: _checkout,
                                        child: const Text(
                                          'Check Out',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(value),
      ],
    );
  }
}
