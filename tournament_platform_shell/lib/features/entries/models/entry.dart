enum EntryStatus { confirmed, unknown }

EntryStatus _statusFromJson(String raw) {
  switch (raw.toLowerCase()) {
    case 'confirmed':
      return EntryStatus.confirmed;
    default:
      return EntryStatus.unknown;
  }
}

class Entry {
  final String id;
  final String categoryId;
  final String playerId;
  final String playerDisplayName;
  final EntryStatus status;
  final DateTime createdAt;

  const Entry({
    required this.id,
    required this.categoryId,
    required this.playerId,
    required this.playerDisplayName,
    required this.status,
    required this.createdAt,
  });

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        id: json['id'] as String,
        categoryId: json['category'] as String,
        playerId: json['player_id'] as String,
        playerDisplayName: json['player_display_name'] as String,
        status: _statusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
