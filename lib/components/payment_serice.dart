// lib/components/payment_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> processPayment({
    required int amount,
    required String paymentMethod,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount,
          'paymentMethod': paymentMethod,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to process payment');
      }
    } catch (e) {
      throw Exception('Error processing payment: $e');
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(
      String sourceId, String type) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-status/$sourceId?type=$type'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check payment status');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }
}
