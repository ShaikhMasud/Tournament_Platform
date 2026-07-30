/// Mirrors accounts.SessionSerializer on the Django side exactly — this is
/// the contract that drives which screens/nav items the app shows, per the
/// UI page inventory's "capability matrix".
class PlayerProfileSummary {
  PlayerProfileSummary({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory PlayerProfileSummary.fromJson(Map<String, dynamic> json) =>
      PlayerProfileSummary(id: json['id'] as String, displayName: json['display_name'] as String);
}

class Capability {
  Capability({required this.capability, required this.isActive});

  final String capability;
  final bool isActive;

  factory Capability.fromJson(Map<String, dynamic> json) =>
      Capability(capability: json['capability'] as String, isActive: json['is_active'] as bool);
}

class TournamentRoleSummary {
  TournamentRoleSummary({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.role,
    required this.isActive,
    required this.capabilities,
  });

  final String id;
  final String tournamentId;
  final String tournamentName;
  final String role; // 'organizer' | 'assistant'
  final bool isActive;
  final List<Capability> capabilities;

  bool get isOrganizer => role == 'organizer';
  bool get isAssistant => role == 'assistant';

  bool hasCapability(String name) =>
      capabilities.any((c) => c.capability == name && c.isActive);

  factory TournamentRoleSummary.fromJson(Map<String, dynamic> json) => TournamentRoleSummary(
        id: json['id'] as String,
        tournamentId: json['tournament'] as String,
        tournamentName: json['tournament_name'] as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
        capabilities: (json['capabilities'] as List)
            .map((c) => Capability.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class Session {
  Session({
    required this.userId,
    required this.email,
    required this.playerProfiles,
    required this.tournamentRoles,
  });

  final String userId;
  final String email;
  final List<PlayerProfileSummary> playerProfiles;
  final List<TournamentRoleSummary> tournamentRoles;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        userId: json['id'] as String,
        email: json['email'] as String,
        playerProfiles: (json['player_profiles'] as List)
            .map((p) => PlayerProfileSummary.fromJson(p as Map<String, dynamic>))
            .toList(),
        tournamentRoles: (json['tournament_roles'] as List)
            .map((r) => TournamentRoleSummary.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
