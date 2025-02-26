import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> restaurants = const [
    {
      'image': 'assets/images/restaurant1.png',
      'name': 'SILOGAN NI MEH',
      'location': 'Purok 4 Cabasan, Bacacay, Albay',
      'rating': '5.0 (1000+)',
      'status': 'Open',
    },
    {
      'image': 'assets/images/restaurant1.png',
      'name': 'SILOGAN NI MEH',
      'location': 'Purok 4 Cabasan, Bacacay, Albay',
      'rating': '5.0 (1000+)',
      'status': 'Unavailable',
      'businessHours': '8:30 am - 10:00 pm',
    },
    {
      'image': 'assets/images/restaurant1.png',
      'name': 'SILOGAN NI MEH',
      'location': 'Purok 4 Cabasan, Bacacay, Albay',
      'rating': '5.0 (1000+)',
      'status': 'Unavailable',
      'businessHours': '8:30 am - 10:00 pm',
    },
    {
      'image': 'assets/images/restaurant1.png',
      'name': 'SILOGAN NI MEH',
      'location': 'Purok 4 Cabasan, Bacacay, Albay',
      'rating': '5.0 (1000+)',
      'status': 'Open',
    },
    {
      'image': 'assets/images/restaurant1.png',
      'name': 'SILOGAN NI MEH',
      'location': 'Purok 4 Cabasan, Bacacay, Albay',
      'rating': '5.0 (1000+)',
      'status': 'Open',
    },
    {
      'image': 'assets/images/restaurant1.png',
      'name': 'SILOGAN NI MEH',
      'location': 'Purok 4 Cabasan, Bacacay, Albay',
      'rating': '5.0 (1000+)',
      'status': 'Unavailable',
      'businessHours': '8:30 am - 10:00 pm',
    },
  ];

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
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 5),
                      hintText: 'Restaurant Search',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Explore Restaurants',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Column(
                      children: restaurants.map((restaurant) {
                        return _buildRestaurantCard(
                          image: restaurant['image'],
                          name: restaurant['name'],
                          location: restaurant['location'],
                          rating: restaurant['rating'],
                          status: restaurant['status'],
                          businessHours: restaurant['businessHours'],
                        );
                      }).toList(),
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

  Widget _buildRestaurantCard({
    required String image,
    required String name,
    required String location,
    required String rating,
    required String status,
    String? businessHours,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  height: 120,
                  width: double.infinity,
                ),
              ),
              if (status == 'Unavailable')
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
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
                          if (businessHours != null)
                            Text(
                              'Business Hours: $businessHours',
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
                        name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(rating),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style:
                            const TextStyle(fontSize: 14, color: Color.fromARGB(255, 84, 83, 83)),
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
    );
  }
}
