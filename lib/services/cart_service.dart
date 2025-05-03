// lib/services/cart_service.dart
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Add this import

class CartService {
  static Future<void> deleteCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        // First get the order to get item IDs
        final orderResponse = await http.get(
          Uri.parse('${dotenv.env['API_BASE_URL']}/orders/$userId'),
        );

        if (orderResponse.statusCode == 200) {
          final orderData = json.decode(orderResponse.body)['order'];
          if (orderData != null && orderData['items'] != null) {
            // Delete each item
            for (var item in orderData['items']) {
              final itemId = item['id'];
              await http.delete(
                Uri.parse(
                    '${dotenv.env['API_BASE_URL']}/orders/$userId/items/$itemId'),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error deleting cart items: $e');
    }
  }
}
