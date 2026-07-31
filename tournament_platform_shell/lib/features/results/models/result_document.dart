/// Model mirroring ResultDocumentSerializer on the Django side.
class ResultDocument {
  ResultDocument({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.status,
    this.downloadUrl,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String tournamentName;
  final String status;
  final String? downloadUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReady => status == 'ready';
  bool get isPending => status == 'pending' || status == 'generating';
  bool get isFailed => status == 'failed';

  factory ResultDocument.fromJson(Map<String, dynamic> json) => ResultDocument(
        id: json['id'] as String,
        tournamentId: json['tournament'] as String,
        tournamentName: json['tournament_name'] as String? ?? '',
        status: json['status'] as String,
        downloadUrl: json['download_url'] as String?,
        errorMessage: json['error_message'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
