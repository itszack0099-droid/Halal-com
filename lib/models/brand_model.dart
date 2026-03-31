class BrandModel {
  final String id;
  final String name;
  final String status; // 'halal' | 'haram' | 'doubtful'
  final String? logoUrl;
  final String? country;
  final String? reason;
  final DateTime? createdAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.status,
    this.logoUrl,
    this.country,
    this.reason,
    this.createdAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'doubtful',
      logoUrl: json['logo_url'],
      country: json['country'],
      reason: json['reason'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'logo_url': logoUrl,
      'country': country,
      'reason': reason,
    };
  }

  bool get isHalal => status == 'halal';
  bool get isHaram => status == 'haram';
  bool get isDoubtful => status == 'doubtful';
}
