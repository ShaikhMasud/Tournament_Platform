/// Model mirroring MatchSerializer on the Django side.
class MatchModel {
  MatchModel({
    required this.id,
    required this.tournamentId,
    required this.categoryId,
    required this.categoryName,
    required this.roundNumber,
    required this.slotPosition,
    required this.entry1,
    required this.entry2,
    required this.score,
    required this.status,
    required this.court,
    this.winnerEntryId,
    this.scheduledStart,
    this.actualStart,
    this.actualEnd,
    required this.version,
  });

  final String id;
  final String tournamentId;
  final String categoryId;
  final String categoryName;
  final int roundNumber;
  final int slotPosition;
  final MatchEntry? entry1;
  final MatchEntry? entry2;
  final MatchScore score;
  final String status;
  final MatchCourt? court;
  final String? winnerEntryId;
  final DateTime? scheduledStart;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int version;

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
        id: json['id'] as String,
        tournamentId: json['tournament'] as String,
        categoryId: json['category'] as String,
        categoryName: json['category_name'] as String? ?? '',
        roundNumber: json['round_number'] as int,
        slotPosition: json['slot_position'] as int,
        entry1: json['entry1'] != null
            ? MatchEntry.fromJson(json['entry1'] as Map<String, dynamic>)
            : null,
        entry2: json['entry2'] != null
            ? MatchEntry.fromJson(json['entry2'] as Map<String, dynamic>)
            : null,
        score: MatchScore.fromJson(json['score'] as Map<String, dynamic>? ?? {}),
        status: json['status'] as String,
        court: json['court'] != null
            ? MatchCourt.fromJson(json['court'] as Map<String, dynamic>)
            : null,
        winnerEntryId: json['winner_entry_id'] as String?,
        scheduledStart: json['scheduled_start'] != null
            ? DateTime.parse(json['scheduled_start'] as String)
            : null,
        actualStart: json['actual_start'] != null
            ? DateTime.parse(json['actual_start'] as String)
            : null,
        actualEnd: json['actual_end'] != null
            ? DateTime.parse(json['actual_end'] as String)
            : null,
        version: json['version'] as int,
      );
}

class MatchEntry {
  MatchEntry({required this.id, required this.playerName, required this.seed});

  final String id;
  final String playerName;
  final int? seed;

  factory MatchEntry.fromJson(Map<String, dynamic> json) => MatchEntry(
        id: json['id'] as String,
        playerName: json['player_name'] as String? ?? 'Unknown',
        seed: json['seed'] as int?,
      );
}

class MatchCourt {
  MatchCourt({required this.id, required this.name});

  final String id;
  final String name;

  factory MatchCourt.fromJson(Map<String, dynamic> json) => MatchCourt(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class MatchScore {
  MatchScore({
    required this.entry1Points,
    required this.entry2Points,
  });

  final int entry1Points;
  final int entry2Points;

  factory MatchScore.fromJson(Map<String, dynamic> json) => MatchScore(
        entry1Points: json['entry1_points'] as int? ?? 0,
        entry2Points: json['entry2_points'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'entry1_points': entry1Points,
        'entry2_points': entry2Points,
      };
}

/// Request to schedule a match.
class ScheduleMatchRequest {
  ScheduleMatchRequest({
    this.courtId,
    this.scheduledStart,
  });

  final String? courtId;
  final DateTime? scheduledStart;

  Map<String, dynamic> toJson() => {
        if (courtId != null) 'court_id': courtId,
        if (scheduledStart != null) 'scheduled_start': scheduledStart!.toIso8601String(),
      };
}

/// Request to update match score.
class UpdateScoreRequest {
  UpdateScoreRequest({
    required this.entry1Points,
    required this.entry2Points,
    required this.version,
  });

  final int entry1Points;
  final int entry2Points;
  final int version;

  Map<String, dynamic> toJson() => {
        'score': {
          'entry1_points': entry1Points,
          'entry2_points': entry2Points,
        },
        'version': version,
      };
}
