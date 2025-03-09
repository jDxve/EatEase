import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ScrollableButtons extends StatefulWidget {
  @override
  _ScrollableButtonsState createState() => _ScrollableButtonsState();
}

class _ScrollableButtonsState extends State<ScrollableButtons> {
  int? activeIndex = 0;
  List<String> categories = ["All"];

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
          categories = ["All"];
          categories.addAll(
              categoryData.map((category) => category['name'].toString()).toList());
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      activeIndex == index ? const Color.fromARGB(255, 211, 43, 31) : Colors.white,
                  foregroundColor:
                      activeIndex == index ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: activeIndex == index
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Text(
                  categories[index],
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
