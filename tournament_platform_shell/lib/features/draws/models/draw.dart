/// Model mirroring DrawSerializer on the Django side.
class Draw {
  Draw({
    required this.id,
    required this.categoryId,
    required this.status,
    required this.version,
    required this.createdAt,
    this.finalizedAt,
    this.slots = const [],
  });

  final String id;
  final String categoryId;
  final String status;
  final int version;
  final DateTime createdAt;
  final DateTime? finalizedAt;
  final List<DrawSlot> slots;

  factory Draw.fromJson(Map<String, dynamic> json) => Draw(
        id: json['id'] as String,
        categoryId: json['category'] as String,
        status: json['status'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        finalizedAt: json['finalized_at'] != null
            ? DateTime.parse(json['finalized_at'] as String)
            : null,
        slots: (json['slots'] as List? ?? [])
            .map((s) => DrawSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class DrawSlot {
  DrawSlot({
    required this.id,
    required this.roundNumber,
    required this.position,
    this.entryId,
    this.entryDisplayName,
    required this.isBye,
  });

  final String id;
  final int roundNumber;
  final int position;
  final String? entryId;
  final String? entryDisplayName;
  final bool isBye;

  factory DrawSlot.fromJson(Map<String, dynamic> json) => DrawSlot(
        id: json['id'] as String,
        roundNumber: json['round_number'] as int,
        position: json['position'] as int,
        entryId: json['entry_id'] as String?,
        entryDisplayName: json['entry_display_name'] as String?,
        isBye: json['is_bye'] as bool,
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
