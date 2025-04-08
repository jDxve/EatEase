import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String paymentMethod,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment-intents'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).round(),
          'payment_method_allowed': [paymentMethod],
          'currency': 'PHP',
          'capture_type': 'automatic',
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing payment: $e');
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(
      String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-status/$paymentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  static Future<bool> isPaymentSuccessful(String paymentId) async {
    try {
      final statusResponse = await checkPaymentStatus(paymentId);
      return statusResponse['data']['attributes']['status'] == 'paid';
    } catch (e) {
      return false;
    }
  }
}
