import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eatease/components/scrollable_button.dart';
import 'package:eatease/components/food_card.dart';
import 'package:eatease/screens/mycart_screen.dart';

class DetailsScreen extends StatefulWidget {
  final String restaurantId;
  final String userId; // Add userId parameter

  // Constructor to accept the restaurant ID and user ID
  DetailsScreen({required this.restaurantId, required this.userId});

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic>? restaurantDetails;
  bool isLoading = true;
  String errorMessage = '';
  int? selectedCategory;
  String successMessage = ''; // State variable for success message

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
        print('User  ID: ${widget.userId}'); // Print the user ID
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
    // Show a confirmation dialog when the user tries to leave the screen
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Set background color
          title: Row(
            children: [
              const Icon(Icons.warning,
                  color: Colors.red, size: 30), // Warning icon
              const SizedBox(width: 10),
              const Text('Warning'),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'If you leave this page, the items in your cart will be deleted. Do you want to proceed?',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Do not leave
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteCartItems(); // Call the deleteCartItems function
                Navigator.of(context).pop(true); // Proceed to leave
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false; // Return false if the dialog is dismissed
  }

  Future<void> deleteCartItems() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/orders/${widget.userId}/items"; // Adjust the endpoint as necessary

    try {
      final response = await http.delete(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        print('Cart items deleted successfully');
        setState(() {
          successMessage = 'Cart items deleted successfully';
        });
      } else {
        print('Failed to delete cart items: ${response.body}');
        setState(() {
          successMessage = 'Failed to delete cart items';
        });
      }
    } catch (e) {
      print('Error deleting cart items: $e');
      setState(() {
        successMessage = 'Error deleting cart items';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Set the onWillPop callback
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
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
                            const SizedBox(height: 70),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white),
                                    onPressed: () async {
                                      final shouldLeave = await _onWillPop();
                                      if (shouldLeave) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
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
                                      final userId = widget.userId;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MyCartScreen(
                                                userId: userId,
                                                restaurantId:
                                                    widget.restaurantId)),
                                      );
                                    },
                                    child: Icon(Icons.shopping_cart_outlined,
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
                                            style: TextStyle(
                                              fontSize: 17.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: Color.fromARGB(
                                                    255, 171, 19, 8),
                                                size: 25,
                                              ),
                                              SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  restaurantDetails![
                                                              'address'] !=
                                                          null
                                                      ? '${restaurantDetails!['address']['street']}, ${restaurantDetails!['address']['city']}, ${restaurantDetails!['address']['province']}'
                                                      : 'Location not available',
                                                  style: TextStyle(
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
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                  '(${restaurantDetails!['rating_count']?.toString() ?? '0'})')
                                            ],
                                          ),
                                          // Display the success message above the FoodList
                                          if (successMessage.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                successMessage,
                                                style: TextStyle(
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
                                          FoodList(
                                            restaurantId: widget.restaurantId,
                                            userId: widget.userId,
                                            selectedCategory: selectedCategory,
                                          ) // Pass the selected category ID
                                        ],
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
