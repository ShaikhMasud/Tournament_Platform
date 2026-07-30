class Organization {
  final String id;
  final String name;
  final String ownerId;
  final String ownerDisplayName;
  final DateTime createdAt;

  const Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerDisplayName,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: owner?['id'] as String? ?? '',
      ownerDisplayName: owner?['display_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Only fields the create endpoint accepts — owner is never sent,
  /// it's stamped server-side from the auth token.
  Map<String, dynamic> toCreateJson() => {'name': name};
}