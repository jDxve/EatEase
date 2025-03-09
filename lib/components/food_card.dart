import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double price;
  final VoidCallback onAdd;

  const FoodCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.onAdd,
  }) : super(key: key);

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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.2),
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
  FoodList({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> foodItems = [
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Burger",
      "price": 99.0
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pizza",
      "price": 199.0
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Pasta",
      "price": 149.0
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Sushi",
      "price": 299.0
    },
    {
      "imageUrl": "https://i.ytimg.com/vi/F_x0-cRDP3I/maxresdefault.jpg",
      "title": "Fried Chicken",
      "price": 129.0
    },
  ];

  void _onAddToCart(String foodName) {
    print("Added $foodName to cart");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 385, // Set fixed height
      child: GridView.builder(
        padding: EdgeInsets.zero, // No padding
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(), // Enables smooth scrolling
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two cards per row
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75, // Adjust ratio for better layout
        ),
        itemCount: foodItems.length,
        itemBuilder: (context, index) {
          final food = foodItems[index];
          return FoodCard(
            imageUrl: food["imageUrl"],
            title: food["title"],
            price: food["price"],
            onAdd: () => _onAddToCart(food["title"]),
          );
        },
      ),
    );
  }
}
