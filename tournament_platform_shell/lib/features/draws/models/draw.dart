/// Model mirroring DrawSerializer on the Django side.
class Draw {
  Draw({
    required this.id,
    required this.categoryId,
    required this.format,
    required this.totalRounds,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String format;
  final int totalRounds;
  final String status;
  final DateTime createdAt;

  factory Draw.fromJson(Map<String, dynamic> json) => Draw(
        id: json['id'] as String,
        categoryId: json['category'] as String,
        format: json['format'] as String,
        totalRounds: json['total_rounds'] as int,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Request payload for draw generation.
class DrawGenerateRequest {
  DrawGenerateRequest({this.format});

  final String? format;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (format != null) map['format'] = format;
    return map;
  }
}
