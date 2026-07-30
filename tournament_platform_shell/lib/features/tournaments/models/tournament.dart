class Court {
  final String id;
  final String tournamentId;
  final String name;

  const Court({required this.id, required this.tournamentId, required this.name});

  factory Court.fromJson(Map<String, dynamic> json) => Court(
        id: json['id'] as String,
        tournamentId: json['tournament'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toCreateJson() => {'name': name};
}

class Category {
  final String id;
  final String tournamentId;
  final String name;
  final String drawFormat;
  final int capacity;
  final String status;

  const Category({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.drawFormat,
    required this.capacity,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        tournamentId: json['tournament'] as String,
        name: json['name'] as String,
        drawFormat: json['draw_format'] as String,
        capacity: json['capacity'] as int,
        status: json['status'] as String,
      );

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'draw_format': drawFormat,
        'capacity': capacity,
      };
}

class Tournament {
  final String id;
  final String organizationId;
  final String name;
  final String sport;
  final bool isPublic;
  final DateTime createdAt;
  final List<Category> categories;
  final List<Court> courts;

  const Tournament({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.sport,
    required this.isPublic,
    required this.createdAt,
    this.categories = const [],
    this.courts = const [],
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        organizationId: json['organization'] as String,
        name: json['name'] as String,
        // Defaults to "badminton_single_game" server-side per the
        // scaffold's model default — the client just reflects whatever
        // the server returns.
        sport: json['sport'] as String? ?? 'badminton_single_game',
        isPublic: json['is_public'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        categories: (json['categories'] as List? ?? [])
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList(),
        courts: (json['courts'] as List? ?? [])
            .map((c) => Court.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toCreateJson() => {
        'organization': organizationId,
        'name': name,
        'is_public': isPublic,
      };
}