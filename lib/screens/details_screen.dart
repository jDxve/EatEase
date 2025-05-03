import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eatease/components/scrollable_button.dart';
import 'package:eatease/components/food_card.dart';
import 'package:eatease/screens/mycart_screen.dart';

class DetailsScreen extends StatefulWidget {
  final String restaurantId;
  final String userId;

  const DetailsScreen({
    Key? key,
    required this.restaurantId,
    required this.userId,
  }) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic>? restaurantDetails;
  bool isLoading = true;
  String errorMessage = '';
  int? selectedCategory;
  String successMessage = '';
  bool hasActiveCart = false;

  @override
  void initState() {
    super.initState();
    checkActiveCart();
    fetchRestaurantDetails();
  }

  Future<void> checkActiveCart() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/check_active_cart/${widget.userId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hasActiveCart = data['hasActiveCart'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking active cart: $e');
    }
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
        print('User ID: ${widget.userId}');
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

  void onCategorySelected(int? id) {
    setState(() {
      selectedCategory = id;
    });
  }

  Future<bool> _onWillPop() async {
    if (!hasActiveCart) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Leave Page?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'If you leave this page, the items in your cart will be deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Stay',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          deleteCartItems();
                          Navigator.of(context).pop(true);
                        },
                        child: const Text(
                          'Leave',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return shouldLeave ?? false;
  }

  Future<void> deleteCartItems() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/orders/${widget.userId}/items";

    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        print('Cart items deleted successfully');
      } else {
        print('Failed to delete cart items: ${response.body}');
      }
    } catch (e) {
      print('Error deleting cart items: $e');
    }
  }

  void _handleBackPress() async {
    if (!hasActiveCart) {
      Navigator.pop(context);
      return;
    }

    final shouldLeave = await _onWillPop();
    if (shouldLeave) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : restaurantDetails == null
                      ? const Center(child: Text('Restaurant not found'))
                      : Column(
                          children: [
                            const SizedBox(height: 70),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white),
                                    onPressed: _handleBackPress,
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 30),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MyCartScreen(
                                            userId: widget.userId,
                                            restaurantId: widget.restaurantId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 15, 16, 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 6,
                                      offset: const Offset(2, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Card(
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              restaurantDetails![
                                                      'restaurant_photo'] ??
                                                  '',
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            restaurantDetails!['name'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                              fontSize: 17.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Color.fromARGB(
                                                    255, 171, 19, 8),
                                                size: 25,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  restaurantDetails![
                                                              'address'] !=
                                                          null
                                                      ? '${restaurantDetails!['address']['street']}, ${restaurantDetails!['address']['city']}, ${restaurantDetails!['address']['province']}'
                                                      : 'Location not available',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color.fromARGB(
                                                        255, 19, 5, 5),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Colors.amber,
                                                  size: 25),
                                              Text(
                                                restaurantDetails!['rating']
                                                        ?.toString() ??
                                                    'N/A',
                                                style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                  '(${restaurantDetails!['rating_count']?.toString() ?? '0'})')
                                            ],
                                          ),
                                          if (successMessage.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                successMessage,
                                                style: const TextStyle(
                                                  color: Colors.pink,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          ScrollableButtons(
                                              onCategorySelected:
                                                  onCategorySelected),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: FoodList(
                                        restaurantId: widget.restaurantId,
                                        userId: widget.userId,
                                        selectedCategory: selectedCategory,
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
    );
  }
}
