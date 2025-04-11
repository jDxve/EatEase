import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import the async package
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatease/components/foodorder_card.dart';
import 'package:eatease/components/orderstatus_indecator.dart';

class OrdersScreen extends StatefulWidget {
  final String userId;

  const OrdersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Timer _timer; // Declare a Timer variable
  List<Map<String, dynamic>> _orders = []; // Store orders locally

  @override
  void initState() {
    super.initState();
    fetchOrders(); // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchOrders(); // Fetch orders every second
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      final String apiUrl =
          "${dotenv.env['API_BASE_URL']}/place_orders/${widget.userId}";
      print('Fetching orders from: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        setState(() {
          _orders =
              orders.map((order) => order as Map<String, dynamic>).toList();
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _orders = [];
        });
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      // Handle error if needed
    }
  }

  Future<void> updateOrderStatus(String orderId) async {
    if (orderId.isEmpty) {
      print('Invalid order ID');
      return;
    }

    try {
      final String apiUrl =
          "${dotenv.env['API_BASE_URL']}/update_order/$orderId";
      print('Updating order at: $apiUrl'); // Log the API URL

      // Prepare the request body with the customer ID
      final requestBody = json.encode({
        'customerId': widget.userId, // Ensure this is the correct customer ID
      });

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody, // Include the request body
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the response body

      if (response.statusCode == 200) {
        print('Order updated successfully');
        fetchOrders(); // Refresh the orders after updating
      } else {
        print('Failed to update order: ${response.statusCode}');
        print(
            'Response body: ${response.body}'); // Log the response body for debugging
      }
    } catch (e) {
      print('Error updating order: $e');
    }
  }

  int getOrderStatusNumber(int orderStatus) {
    // Directly use orderStatus to determine the current status
    return orderStatus; // Assuming orderStatus is already 1, 2, or 3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'My Orders',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: _orders.isEmpty
                      ? const Center(
                          child: Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final items = order['items'] as List;
                            final orderStatus = order[
                                'orderStatus']; // Get order status directly

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.white,
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order ID and Total Amount
                                    Text(
                                      'Order #${order['order_id']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total: ₱${order['totalAmount'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Order Status Indicator
                                    OrderStatusIndicator(
                                      currentStatus: getOrderStatusNumber(
                                          orderStatus), // Pass the order status
                                    ),
                                    const SizedBox(height: 10),
                                    // Scrollable list of items
                                    Container(
                                      height: 300,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            ...items.map((item) => FoodOrders(
                                                  name: item['name'],
                                                  imageUrl: item['image'],
                                                  price: double.parse(
                                                      item['price'].toString()),
                                                  quantity: int.parse(
                                                      item['quantity']
                                                          .toString()),
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    // Button to update the order status
                                    // Button to update the order status
// Button to update the order status
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: orderStatus == 3
                                              ? Colors.red
                                              : Colors.grey,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        onPressed: orderStatus == 3
                                            ? () {
                                                // Use 'id' instead of '_id'
                                                updateOrderStatus(order['id']);
                                              }
                                            : null, // Disable button if not ready
                                        child: const Text(
                                          'Mark as Picked Up',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
