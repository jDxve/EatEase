import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ScrollableButtons extends StatefulWidget {
  final Function(int?) onCategorySelected; // Change to accept nullable int

  ScrollableButtons({required this.onCategorySelected}); // Update constructor

  @override
  _ScrollableButtonsState createState() => _ScrollableButtonsState();
}

class _ScrollableButtonsState extends State<ScrollableButtons> {
  int? activeIndex = 0;
  List<Map<String, dynamic>> categories = []; // Change to a list of maps

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final String apiUrl = (Platform.isAndroid)
        ? "http://192.168.1.244:5001/api/categories"
        : "http://localhost:5001/api/categories";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> categoryData = jsonDecode(response.body);

        setState(() {
          categories = [
            {"id": null, "name": "All"}
          ]; // Add "All" category
          categories.addAll(categoryData
              .map((category) =>
                  {"id": category['id'], "name": category['name']})
              .toList());
        });
      }
    } catch (error) {
      print("Error fetching categories: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            categories.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    activeIndex = index;
                  });
                  widget.onCategorySelected(
                      categories[index]['id']); // Pass the category ID
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeIndex == index
                      ? const Color.fromARGB(255, 168, 26, 16)
                      : Colors.white,
                  foregroundColor:
                      activeIndex == index ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Text(
                  categories[index]['name'], // Use category name
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
