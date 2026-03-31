class AiAnalysisResult {
  final String status; // 'halal' | 'haram' | 'doubtful'
  final double confidence; // 0.0 - 1.0
  final String reason;
  final List<String> haramIngredients;
  final List<String> doubtfulIngredients;

  const AiAnalysisResult({
    required this.status,
    required this.confidence,
    required this.reason,
    required this.haramIngredients,
    required this.doubtfulIngredients,
  });

  factory AiAnalysisResult.fallback() {
    return const AiAnalysisResult(
      status: 'doubtful',
      confidence: 0.3,
      reason: 'Unable to analyze ingredients. Marked as doubtful by default.',
      haramIngredients: [],
      doubtfulIngredients: [],
    );
  }

  bool get isHalal => status == 'halal';
  bool get isHaram => status == 'haram';
  bool get isDoubtful => status == 'doubtful';
  int get confidencePercent => (confidence * 100).round();
}
