
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createCheckout({
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-invoice',
      body: {'items': items},
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid response from payment server.');
    }

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    final checkoutUrl = data['checkout_url'];

    if (checkoutUrl is! String || checkoutUrl.isEmpty) {
      throw Exception('Checkout URL was not returned.');
    }

    return checkoutUrl;
  }

  Future<void> openCheckout(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      throw Exception('Invalid checkout URL.');
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception('Could not open Xendit checkout.');
    }
  }
}
