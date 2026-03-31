import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scan_result_model.dart';

class GroqService {
  static const String _k1 = 'gsk_ZUK4HetByk6QIgQf';
  static const String _k2 = 'JMCLWGdyb3FY6KoH8CsM';
  static const String _k3 = 'koBUkCJmwO2SIKgt';
  static String get _apiKey => '$_k1$_k2$_k3';
  static const String _model = 'llama-3.1-8b-instant';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const Duration _timeout = Duration(seconds: 15);

  /// Returns structured halal analysis as [AiAnalysisResult].
  static Future<AiAnalysisResult> analyzeHalalStatus(
    String productName,
    List<String> ingredients,
  ) async {
    if (ingredients.isEmpty) return AiAnalysisResult.fallback();

    final prompt = '''You are a halal food certification expert. Analyze these ingredients for the product "$productName" and respond with ONLY valid JSON, no extra text.

Ingredients: ${ingredients.join(', ')}

Respond with this exact JSON structure:
{
  "status": "halal" | "haram" | "doubtful",
  "confidence": 0.0 to 1.0,
  "reason": "short explanation (max 2 sentences)",
  "haram_ingredients": ["list", "of", "haram", "items"],
  "doubtful_ingredients": ["list", "of", "questionable", "items"]
}

Rules:
- haram: contains pork, gelatin from unknown/pork source, alcohol, lard, carmine, or other clearly forbidden ingredients
- doubtful: contains natural flavors, mono/diglycerides, vanilla extract, emulsifiers from unknown source
- halal: all ingredients are permissible
- confidence should reflect certainty (1.0 = very sure, 0.5 = uncertain)''';

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'max_tokens': 300,
              'temperature': 0.1,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return AiAnalysisResult.fallback();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return AiAnalysisResult.fallback();

      return _parseResult(content);
    } catch (_) {
      return AiAnalysisResult.fallback();
    }
  }

  static AiAnalysisResult _parseResult(String content) {
    try {
      // Extract JSON from response (in case there's surrounding text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) return AiAnalysisResult.fallback();

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      final status = json['status']?.toString().toLowerCase() ?? 'doubtful';
      final validStatuses = {'halal', 'haram', 'doubtful'};
      final safeStatus = validStatuses.contains(status) ? status : 'doubtful';

      final confidence = (json['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5;
      final reason = json['reason']?.toString() ?? 'Analysis complete.';

      final haramList = json['haram_ingredients'];
      final doubtfulList = json['doubtful_ingredients'];

      return AiAnalysisResult(
        status: safeStatus,
        confidence: confidence,
        reason: reason,
        haramIngredients: haramList is List
            ? haramList.map((e) => e.toString()).toList()
            : [],
        doubtfulIngredients: doubtfulList is List
            ? doubtfulList.map((e) => e.toString()).toList()
            : [],
      );
    } catch (_) {
      return AiAnalysisResult.fallback();
    }
  }

  /// Legacy: returns plain text analysis string.
  static Future<String> analyzeIngredients(
    String productName,
    List<String> ingredients,
  ) async {
    final result = await analyzeHalalStatus(productName, ingredients);
    return result.reason;
  }
}
