import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatease/components/foodorder_card.dart';
import 'package:eatease/components/orderstatus_indecator.dart';
import 'package:eatease/screens/message_screen.dart';

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
  late Timer _timer;
  List<Map<String, dynamic>> _orders = [];
  String? restaurantId; // Declare a variable to hold the restaurant ID

  @override
  void initState() {
    super.initState();
    fetchOrders();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchOrders();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
        final List<dynamic> orders = json.decode(response.body) ?? [];
        setState(() {
          _orders = orders.map((order) {
            // Extract restaurant ID directly from the order object
            if (order['restaurantId'] != null) {
              restaurantId = order['restaurantId']; // Extract restaurant ID
              print('Restaurant ID: $restaurantId'); // Print restaurant ID
            }
            return order as Map<String, dynamic>;
          }).toList();

          // If you want to ensure restaurantId is set to the first valid restaurant ID
          if (_orders.isNotEmpty && restaurantId == null) {
            restaurantId = _orders.first['restaurantId'];
            print('First Restaurant ID: $restaurantId');
          }
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
      print('Updating order at: $apiUrl');

      final requestBody = json.encode({
        'customerId': widget.userId,
      });

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Order updated successfully');
        fetchOrders();
      } else {
        print('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating order: $e');
    }
  }

  int getOrderStatusNumber(int orderStatus) {
    return orderStatus;
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Orders',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: SizedBox(
                        height: 25,
                        width: 25,
                        child: ColorFiltered(
                          colorFilter:
                              ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          child: Image.asset('assets/images/chat.png'),
                        ),
                      ),
                      onPressed: () {
                        if (restaurantId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(
                                userId: widget.userId,
                                restaurantId: restaurantId!,
                              ),
                            ),
                          );
                        } else {
                          print('Restaurant ID is not available');
                        }
                      },
                    )
                  ],
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
                            final orderStatus = order['orderStatus'];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.white,
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    OrderStatusIndicator(
                                      currentStatus:
                                          getOrderStatusNumber(orderStatus),
                                    ),
                                    const SizedBox(height: 10),
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
                                                updateOrderStatus(order['id']);
                                              }
                                            : null,
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
