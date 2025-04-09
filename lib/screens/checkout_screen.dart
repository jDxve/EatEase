import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eatease/components/fooditem_checkout.dart';
import 'package:eatease/components/step_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatease/components/payment_serice.dart';
import 'package:eatease/screens/webview_screen.dart';
import 'package:eatease/components/bottom_nav.dart';

class CheckoutScreen extends StatefulWidget {
  final String? userId;
  final String restaurantId;

  const CheckoutScreen({
    super.key,
    this.userId,
    required this.restaurantId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  TimeOfDay? selectedTime;
  int currentStep = 3;
  Map<String, dynamic>? restaurantDetails;
  List<Map<String, dynamic>> foodItems = [];
  bool isLoading = true;
  String errorMessage = '';
  int _selectedPaymentOption = 0;

  @override
  void initState() {
    super.initState();
    fetchRestaurantDetails();
  }

  Future<void> fetchRestaurantDetails() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/restaurants/${widget.restaurantId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          restaurantDetails = json.decode(response.body);
          isLoading = false;
        });
        fetchFoodItems();
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Exception: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchFoodItems() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/orders/${widget.userId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['order'] != null) {
          setState(() {
            foodItems = List<Map<String, dynamic>>.from(data['order']['items']);
          });
        } else {
          setState(() {
            errorMessage = 'No order found.';
          });
        }
      } else {
        final data = json.decode(response.body);
        setState(() {
          errorMessage = 'Failed to load food items: ${data['error']}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.red,
            colorScheme: const ColorScheme.light(primary: Colors.red),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> placeOrder() async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User  ID is not available')),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup time')),
      );
      return;
    }

    try {
      String? paymentMethod;
      switch (_selectedPaymentOption) {
        case 0: // Cash payment
          await _processCashPayment();
          return;
        case 1: // GCash
          paymentMethod = 'gcash';
          break;
        case 2: // Grab Pay
          paymentMethod = 'grab_pay';
          break;
      }

      if (paymentMethod != null) {
        final totalAmount = calculateTotalAmount();
        final description =
            'Payment for order at ${restaurantDetails!['name']}';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(child: CircularProgressIndicator());
          },
        );

        try {
          final paymentResult = await PaymentService.processPayment(
            amount: (totalAmount * 100).round(),
            paymentMethod: paymentMethod,
            description: description,
          );

          Navigator.pop(context); // Hide loading

          if (paymentResult['success'] == true) {
            final checkoutUrl = paymentResult['checkoutUrl'];
            final sourceId = paymentResult['data']['data']['id'];

            bool paymentComplete = false;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebViewScreen(
                  url: checkoutUrl,
                  onComplete: (success) async {
                    paymentComplete = success;
                    if (success) {
                      await _processCashPayment();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment successful!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Payment was not completed')),
                      );
                    }
                  },
                ),
              ),
            );

            // Start checking payment status
            if (!paymentComplete) {
              Timer.periodic(Duration(seconds: 5), (timer) async {
                try {
                  final statusResult = await PaymentService.checkPaymentStatus(
                      sourceId, paymentMethod!);
                  final status =
                      statusResult['data']['data']['attributes']['status'];

                  if (status == 'paid') {
                    timer.cancel();
                    await _processCashPayment();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment successful!')),
                    );
                  } else if (status == 'expired' || status == 'cancelled') {
                    timer.cancel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Payment was not completed')),
                    );
                  }
                } catch (e) {
                  timer.cancel();
                  print('Error checking payment status: $e');
                }
              });
            }
          }
        } catch (e) {
          Navigator.pop(context); // Hide loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment error: $e')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _processCashPayment() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/orders/${widget.userId}";

    final Map<String, dynamic> requestBody = {
      'order_stage': 'place order',
      'pickup_time': selectedTime != null
          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
          : DateTime.now().toString().split(' ')[1].split('.')[0],
    };

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to BottomNav with OrdersScreen active
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNav(
              userId: widget.userId ?? '',
              initialIndex: 2, // Set initial index to OrdersScreen
            ),
          ),
          (route) => false, // This removes all previous routes
        );
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exception: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double calculateTotalAmount() {
    return foodItems.fold(
        0, (total, item) => total + (item['price'] * item['quantity']));
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
        child: Column(
          children: [
            const SizedBox(height: 70),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 60),
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
                    : errorMessage.isNotEmpty
                        ? Center(child: Text(errorMessage))
                        : restaurantDetails == null
                            ? Center(child: Text('Restaurant not found'))
                            : Column(
                                children: [
                                  StepIndicator(currentStep: currentStep),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          restaurantDetails![
                                                  'restaurant_photo'] ??
                                              '',
                                          width: 70,
                                          height: 45,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            restaurantDetails!['name'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color.fromARGB(
                                                  255, 137, 20, 12),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  color: Colors.red, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                restaurantDetails!['address'] !=
                                                        null
                                                    ? '${restaurantDetails!['address']['street'] ?? 'Street not available'}, ${restaurantDetails!['address']['city'] ?? 'City not available'}, ${restaurantDetails!['address']['province'] ?? 'Province not available'}'
                                                    : 'Location not available',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Colors.amber,
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                restaurantDetails!['rating']
                                                        ?.toString() ??
                                                    'N/A',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color.fromARGB(
                                                      255, 137, 20, 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pickup Time',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 20),
                                            child: const Text(
                                              'Required:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0),
                                            child: Container(
                                              width: 140,
                                              height: 30,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _selectTime(context),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                        Icons.access_time,
                                                        color: Colors.white,
                                                        size: 20),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      selectedTime != null
                                                          ? selectedTime!
                                                              .format(context)
                                                          : 'Select Time',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 15,
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
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: const Text(
                                        'Order Lists',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Expanded(
                                    child: ListView(
                                      padding: EdgeInsets.zero,
                                      children: foodItems.map((foodItem) {
                                        return FoodItemCheckout(
                                          name: foodItem['name'],
                                          imageUrl: foodItem['image'] ??
                                              'assets/images/restaurant1.png',
                                          price: foodItem['price'].toDouble(),
                                          quantity: foodItem['quantity'],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const Divider(thickness: 1, height: 20),
                                  Padding(
                                    padding: EdgeInsets.all(0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Amount',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 210),
                                        Expanded(
                                          child: Text(
                                            NumberFormat.currency(
                                                    locale: 'en_PH',
                                                    symbol: '₱ ')
                                                .format(
                                                    calculateTotalAmount()), // Format the total amount
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 185, 14, 14),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Container(
                                      width: double.infinity,
                                      height: 155,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE6EA),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              'Payment Options',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0, right: 20.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPaymentOption = 0;
                                                });
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                          'assets/images/Cash.png',
                                                          height: 20.0,
                                                          width: 20.0),
                                                      SizedBox(width: 8.0),
                                                      Text('Cash Payment',
                                                          style: TextStyle(
                                                              fontSize: 16)),
                                                    ],
                                                  ),
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                    ),
                                                    child: Center(
                                                      child: Container(
                                                        width:
                                                            _selectedPaymentOption ==
                                                                    0
                                                                ? 10
                                                                : 0,
                                                        height:
                                                            _selectedPaymentOption ==
                                                                    0
                                                                ? 10
                                                                : 0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0, right: 20.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPaymentOption = 1;
                                                });
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                          'assets/images/Wallet.png',
                                                          height: 20.0,
                                                          width: 20.0),
                                                      SizedBox(width: 8.0),
                                                      Text('GCash',
                                                          style: TextStyle(
                                                              fontSize: 16)),
                                                    ],
                                                  ),
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                    ),
                                                    child: Center(
                                                      child: Container(
                                                        width:
                                                            _selectedPaymentOption ==
                                                                    1
                                                                ? 10
                                                                : 0,
                                                        height:
                                                            _selectedPaymentOption ==
                                                                    1
                                                                ? 10
                                                                : 0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0, right: 20.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPaymentOption = 2;
                                                });
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                          'assets/images/CreditCard.png',
                                                          height: 20.0,
                                                          width: 20.0),
                                                      SizedBox(width: 8.0),
                                                      Text('Grab Pay',
                                                          style: TextStyle(
                                                              fontSize: 16)),
                                                    ],
                                                  ),
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                    ),
                                                    child: Center(
                                                      child: Container(
                                                        width:
                                                            _selectedPaymentOption ==
                                                                    2
                                                                ? 10
                                                                : 0,
                                                        height:
                                                            _selectedPaymentOption ==
                                                                    2
                                                                ? 10
                                                                : 0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: SizedBox(
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
                                        onPressed: () {
                                          placeOrder(); // Call the placeOrder method
                                        },
                                        child: const Text(
                                          'Place Order',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
