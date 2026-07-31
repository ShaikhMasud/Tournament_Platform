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

class DrawEntry {
  DrawEntry({
    required this.id,
    required this.displayName,
    this.seed,
  });

  final String id;
  final String displayName;
  final int? seed;

  factory DrawEntry.fromJson(Map<String, dynamic> json) => DrawEntry(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? json['player_name'] as String? ?? 'Unknown',
        seed: json['seed'] as int?,
      );
}

class DrawSlot {
  DrawSlot({
    required this.id,
    required this.roundNumber,
    required this.slotPosition,
    this.entry1,
    this.entry2,
    this.winnerEntryId,
  });

  final String id;
  final int roundNumber;
  final int slotPosition;
  final DrawEntry? entry1;
  final DrawEntry? entry2;
  final String? winnerEntryId;

  factory DrawSlot.fromJson(Map<String, dynamic> json) => DrawSlot(
        id: json['id'] as String,
        roundNumber: json['round_number'] as int,
        slotPosition: json['slot_position'] as int,
        entry1: json['entry1'] != null
            ? DrawEntry.fromJson(json['entry1'] as Map<String, dynamic>)
            : null,
        entry2: json['entry2'] != null
            ? DrawEntry.fromJson(json['entry2'] as Map<String, dynamic>)
            : null,
        winnerEntryId: json['winner_entry_id'] as String?,
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
