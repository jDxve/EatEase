import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON decoding

class FoodCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double price;
  final int category;
  final VoidCallback onAdd;

  const FoodCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.category,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      margin: const EdgeInsets.only(bottom: 10.0, left: 5, right: 5),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₱ $price",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 183, 39, 29),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FoodList extends StatefulWidget {
  final String restaurantId;
  final int? selectedCategory;

  FoodList({Key? key, required this.restaurantId, this.selectedCategory})
      : super(key: key);

  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  List<Map<String, dynamic>> foodItems = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchFoodItems();
  }

  Future<void> fetchFoodItems() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/restaurants/${widget.restaurantId}/menu";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          foodItems = List<Map<String, dynamic>>.from(data['menu']);
          isLoading = false;
        });
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

  void _onAddToCart(String foodName) {
    print("Added $foodName to cart");
  }

  @override
  Widget build(BuildContext context) {
    // Filter food items based on the selected category
    final filteredFoodItems = widget.selectedCategory == null
        ? foodItems
        : foodItems
            .where((food) => food['category_id'] == widget.selectedCategory)
            .toList();

    return Container(
      height: 360,
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredFoodItems.length,
                  itemBuilder: (context, index) {
                    final food = filteredFoodItems[index];
                    return FoodCard(
                      imageUrl: food["image_url"],
                      title: food["name"],
                      price: (food["price"] is int)
                          ? (food["price"] as int).toDouble()
                          : food["price"],
                      category: food["category_id"],
                      onAdd: () => _onAddToCart(food["name"]),
                    );
                  },
                ),
    );
  }
}
