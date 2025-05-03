import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatease/components/foodorder_card.dart';
import 'package:eatease/components/orderstatus_indecator.dart';
import 'package:eatease/screens/message_screen.dart';
import 'package:eatease/components/bottom_nav.dart';

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

  Future<void> cancelOrder(String orderId) async {
  if (orderId.isEmpty) {
    print('Invalid order ID');
    return;
  }

  try {
    final String apiUrl = "${dotenv.env['API_BASE_URL']}/cancel_order/$orderId";
    print('Cancelling order at: $apiUrl');

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
      print('Order cancelled successfully');
      
      // Navigate to home screen (assuming index 0 is home)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNav(
            userId: widget.userId,
            initialIndex: 0,
          ),
        ),
      );

      // Show the notification at the top after navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              content: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Order Cancelled',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your order has been cancelled successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'OK',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      });

    } else {
      print('Failed to cancel order: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error cancelling order: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
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
                                      child: orderStatus == 1
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              onPressed: () {
                                                // Show confirmation dialog before cancelling
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Cancel Order'),
                                                      content: const Text(
                                                          'Are you sure you want to cancel this order?'),
                                                      actions: [
                                                        TextButton(
                                                          child:
                                                              const Text('No'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        ),
                                                        TextButton(
                                                          child:
                                                              const Text('Yes'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            cancelOrder(
                                                                order['id']);
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: const Text(
                                                'Cancel Order',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    orderStatus == 3
                                                        ? Colors.red
                                                        : Colors.grey,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              onPressed: orderStatus == 3
                                                  ? () {
                                                      updateOrderStatus(
                                                          order['id']);
                                                    }
                                                  : null,
                                              child: const Text(
                                                'Mark as Picked Up',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
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
