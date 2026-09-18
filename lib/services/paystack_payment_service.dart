import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaystackPaymentService {
  static Future<void> startCheckout({
    required String orderId,
    required double amount,
    required String buyerEmail,
    List<String>? orderIds,
  }) async {
    final directFunctionUrl = dotenv.env['PAYSTACK_CREATE_TRANSACTION_URL']?.trim();
    final baseFunctionUrl = dotenv.env['FUNCTIONS_API_BASE_URL']?.trim();
    final secretKey = dotenv.env['PAYSTACK_SECRET_KEY']?.trim();

    String? authorizationUrl;

    // 1. Try custom backend Cloud Function endpoint if configured
    if ((directFunctionUrl != null && directFunctionUrl.isNotEmpty) ||
        (baseFunctionUrl != null && baseFunctionUrl.isNotEmpty)) {
      try {
        final Uri uri = directFunctionUrl != null && directFunctionUrl.isNotEmpty
            ? Uri.parse(directFunctionUrl)
            : Uri.parse('${baseFunctionUrl!.replaceFirst(RegExp(r'/$'), '')}/createTransaction');

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
            'amount': amount,
            'buyerEmail': buyerEmail,
            if (orderIds != null) 'orderIds': orderIds,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          authorizationUrl = (body['authorizationUrl'] as String?) ??
              (body['data'] is Map ? body['data']['authorization_url'] as String? : null);
        }
      } catch (_) {
        // Fallback to direct Paystack API if cloud function fails
      }
    }

    // 2. Direct Paystack API initialization if no backend URL or backend call returned no URL
    if (authorizationUrl == null || authorizationUrl.isEmpty) {
      if (secretKey == null || secretKey.isEmpty) {
        throw Exception(
          'Paystack key missing: Set PAYSTACK_SECRET_KEY or FUNCTIONS_API_BASE_URL in .env.',
        );
      }

      final int amountInSubunits = (amount * 100).round();
      final String cleanReference = orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final callbackUrl = dotenv.env['PAYSTACK_CALLBACK_URL']?.trim();

      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': buyerEmail.trim(),
          'amount': amountInSubunits,
          'reference': cleanReference,
          if (callbackUrl != null && callbackUrl.isNotEmpty && !callbackUrl.contains('#'))
            'callback_url': callbackUrl,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errBody = jsonDecode(response.body);
        final msg = errBody is Map ? errBody['message'] ?? response.body : response.body;
        throw Exception('Paystack API: $msg');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      authorizationUrl = data?['authorization_url'] as String?;
    }

    if (authorizationUrl == null || authorizationUrl.isEmpty) {
      throw Exception('Payment link was not returned by Paystack.');
    }

    // 3. Launch Paystack checkout page
    final Uri paystackUri = Uri.parse(authorizationUrl);
    bool launched = false;
    try {
      launched = await launchUrl(
        paystackUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      launched = await launchUrl(
        paystackUri,
        mode: LaunchMode.platformDefault,
      );
    }

    if (!launched) {
      throw Exception('Unable to open Paystack payment page.');
    }
  }
}
