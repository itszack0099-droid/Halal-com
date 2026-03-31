import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? ingredientsText;
  final List<String> ingredients;
  final String? country;
  final bool found;

  const OpenFoodFactsProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.ingredientsText,
    required this.ingredients,
    this.country,
    required this.found,
  });

  factory OpenFoodFactsProduct.notFound(String barcode) {
    return OpenFoodFactsProduct(
      barcode: barcode,
      name: '',
      ingredients: [],
      found: false,
    );
  }
}

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<OpenFoodFactsProduct> lookupBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'HalalCom/1.0 (Flutter; halalbillionaires@gmail.com)',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        return OpenFoodFactsProduct.notFound(barcode);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'];

      if (status != 1) {
        return OpenFoodFactsProduct.notFound(barcode);
      }

      final product = data['product'] as Map<String, dynamic>? ?? {};

      final name = _firstNonEmpty([
        product['product_name_en'],
        product['product_name'],
        product['abbreviated_product_name'],
      ]) ?? 'Unknown Product';

      final brand = _firstNonEmpty([
        product['brands'],
        product['brand_owner'],
      ]);

      final imageUrl = _firstNonEmpty([
        product['image_front_url'],
        product['image_url'],
        product['image_front_small_url'],
      ]);

      final ingredientsText = _firstNonEmpty([
        product['ingredients_text_en'],
        product['ingredients_text'],
      ]);

      final ingredients = _parseIngredients(product);

      final country = _firstNonEmpty([
        product['countries'],
        product['manufacturing_places'],
      ]);

      return OpenFoodFactsProduct(
        barcode: barcode,
        name: name,
        brand: brand,
        imageUrl: imageUrl,
        ingredientsText: ingredientsText,
        ingredients: ingredients,
        country: country,
        found: true,
      );
    } catch (_) {
      return OpenFoodFactsProduct.notFound(barcode);
    }
  }

  static String? _firstNonEmpty(List<dynamic?> values) {
    for (final v in values) {
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  static List<String> _parseIngredients(Map<String, dynamic> product) {
    final results = <String>[];

    // Try structured ingredients list first
    final structured = product['ingredients'];
    if (structured is List) {
      for (final item in structured) {
        if (item is Map) {
          final text = item['text']?.toString() ?? item['id']?.toString();
          if (text != null && text.trim().isNotEmpty) {
            results.add(text.trim());
          }
        }
      }
      if (results.isNotEmpty) return results;
    }

    // Fall back to parsing ingredients_text
    final raw = _firstNonEmpty([
      product['ingredients_text_en'],
      product['ingredients_text'],
    ]);
    if (raw == null) return [];

    final cleaned = raw
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '');

    final parts = cleaned.split(RegExp(r'[,;]'));
    for (final part in parts) {
      final trimmed = part.trim().replaceAll(RegExp(r'^[-•*]\s*'), '');
      if (trimmed.isNotEmpty && trimmed.length < 80) {
        results.add(trimmed);
      }
    }
    return results;
  }
}
