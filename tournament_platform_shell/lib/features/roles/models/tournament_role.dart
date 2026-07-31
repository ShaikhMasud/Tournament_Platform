/// Models for tournament role management.
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
    required this.userEmail,
    required this.role,
    required this.isActive,
    required this.capabilities,
  });

  final String id;
  final String tournamentId;
  final String tournamentName;
  final String userEmail;
  final String role;
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
        userEmail: json['user_email'] as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
        capabilities: (json['capabilities'] as List)
            .map((c) => Capability.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
