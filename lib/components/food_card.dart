import 'package:flutter/material.dart';

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

class FoodList extends StatelessWidget {
  final int? selectedCategory; // Add this line

  FoodList({Key? key, this.selectedCategory})
      : super(key: key); // Update constructor

  final List<Map<String, dynamic>> foodItems = [
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Burger",
      "price": 99.0,
      "category": 1,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Burger",
      "price": 99.0,
      "category": 1,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0,
      "category": 2,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0,
      "category": 2,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0,
      "category": 2,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pasta",
      "price": 149.0,
      "category": 3,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0,
      "category": 3,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Sushi",
      "price": 299.0,
      "category": 4,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0,
      "category": 4,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Fried Chicken",
      "price": 129.0,
      "category": 5,
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0,
      "category": 5,
    },
  ];

  void _onAddToCart(String foodName) {
    print("Added $foodName to cart");
  }

  @override
  Widget build(BuildContext context) {
    // Filter food items based on the selected category
    final filteredFoodItems = selectedCategory == null
        ? foodItems
        : foodItems
            .where((food) => food['category'] == selectedCategory)
            .toList();

    return Container(
      height: 365,
      child: GridView.builder(
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
            imageUrl: food["imageUrl"],
            title: food["title"],
            price: food["price"],
            category: food["category"],
            onAdd: () => _onAddToCart(food["title"]),
          );
        },
      ),
    );
  }
}
