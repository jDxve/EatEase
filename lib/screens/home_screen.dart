import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'details_screen.dart';
import 'package:eatease/screens/orders_screen.dart';
import 'package:eatease/components/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  bool isLoading = true;
  bool hasPendingOrder = false;
  String? pendingOrderRestaurantId;
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
    checkPendingOrders();
    _searchController.addListener(_filterRestaurants);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchRestaurants();
      checkPendingOrders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isRestaurantOpen(
      TimeOfDay currentTime, TimeOfDay openTime, TimeOfDay closeTime) {
    if (closeTime.hour < openTime.hour) {
      return currentTime.hour > openTime.hour ||
          currentTime.hour < closeTime.hour ||
          (currentTime.hour == openTime.hour &&
              currentTime.minute >= openTime.minute) ||
          (currentTime.hour == closeTime.hour &&
              currentTime.minute < closeTime.minute);
    }
    return (currentTime.hour > openTime.hour ||
            (currentTime.hour == openTime.hour &&
                currentTime.minute >= openTime.minute)) &&
        (currentTime.hour < closeTime.hour ||
            (currentTime.hour == closeTime.hour &&
                currentTime.minute < closeTime.minute));
  }

  String _buildLocationString(Map<String, dynamic>? address) {
    if (address == null) return 'Location not available';
    return [address['street'], address['city'], address['province']]
        .where((s) => s?.isNotEmpty == true)
        .join(', ');
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? parts[1] : '00';
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $suffix';
  }

  Future<void> checkPendingOrders() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/pending_orders/${widget.userId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> pendingOrders = json.decode(response.body);
        setState(() {
          hasPendingOrder = pendingOrders.isNotEmpty;
          pendingOrderRestaurantId = pendingOrders.isNotEmpty
              ? pendingOrders.first['restaurant_id']
              : null;
        });

        // Only show SnackBar if this is the first check (when mounting)
        if (pendingOrders.isNotEmpty && _timer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You have pending orders. Please pick them up before placing a new order.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BottomNav(
                        userId: widget.userId,
                        initialIndex: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking pending orders: $e');
    }
  }

  Future<void> fetchRestaurants() async {
    final String apiUrl = "${dotenv.env['API_BASE_URL']}/restaurants";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final now = DateTime.now();
        final currentTime = TimeOfDay.fromDateTime(now);

        List<Map<String, dynamic>> parsedRestaurants = data.map((item) {
          try {
            String id = item['_id'];
            final openTimeStr = item['operating_hours']?['open'] ?? '00:00';
            final closeTimeStr = item['operating_hours']?['close'] ?? '00:00';
            final openTime = _parseTimeString(openTimeStr);
            final closeTime = _parseTimeString(closeTimeStr);
            bool isOpen = _isRestaurantOpen(currentTime, openTime, closeTime);

            return {
              'id': id,
              'image': item['restaurant_photo'] ?? '',
              'name': item['name'] ?? 'Unknown',
              'location': _buildLocationString(item['address']),
              'rating': item['rating']?.toString() ?? 'N/A',
              'rating_count': item['rating_count']?.toString() ?? '0',
              'status': isOpen ? 'Open' : 'Unavailable',
              'businessHours':
                  '${_formatTime(openTimeStr)} - ${_formatTime(closeTimeStr)}',
              'dbStatus': item['status'].toString(),
            };
          } catch (e) {
            print('Error parsing restaurant: $e');
            return {'name': 'Invalid data', 'status': 'Unavailable'};
          }
        }).toList();

        parsedRestaurants = parsedRestaurants.where((restaurant) {
          return restaurant['dbStatus'] == '2';
        }).toList();

        setState(() {
          restaurants = parsedRestaurants;
          filteredRestaurants = parsedRestaurants;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load restaurants');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterRestaurants() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredRestaurants = restaurants.where((restaurant) {
        return restaurant['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([
      fetchRestaurants(),
      checkPendingOrders(),
    ]);
  }

  void _navigateToDetails(
      BuildContext context, Map<String, dynamic> restaurant) {
    if (hasPendingOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You have pending orders. Please pick them up before placing a new order.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BottomNav(
                    userId: widget.userId,
                    initialIndex: 2,
                  ),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    if (restaurant['status'] == 'Unavailable') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This restaurant is currently closed',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          restaurantId: restaurant['id'],
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              const SizedBox(height: 70),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 80),
                  child: Image.asset(
                    'assets/images/logo2.png',
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 5),
                      hintText: 'Search Restaurant',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
                child: const Text(
                  'Explore Restaurants',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredRestaurants.isEmpty
                            ? const Center(
                                child: Text(
                                  'No restaurants found',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredRestaurants.length,
                                itemBuilder: (context, index) {
                                  final restaurant = filteredRestaurants[index];
                                  return _buildRestaurantCard(restaurant);
                                },
                              ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context, restaurant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Image.network(
                    restaurant['image'],
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 145,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 40),
                      );
                    },
                  ),
                ),
                if (restaurant['status'] == 'Unavailable')
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Unavailable',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Business Hours: ${restaurant['businessHours']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (hasPendingOrder &&
                    restaurant['id'] == pendingOrderRestaurantId)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You have pending orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(
                            restaurant['rating'],
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('(${restaurant['rating_count']})'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant['location'],
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
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
