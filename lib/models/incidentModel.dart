// lib/models/incidentModel.dart

enum IncidentStatus { pending, inProgress, resolved, rejected }

enum IncidentPriority { low, medium, high }

// ── Entrada del historial de cambios de estado ─────────────────────────────
class StatusHistoryEntry {
  final IncidentStatus status;
  final DateTime changedAt;
  final String? comment; // nota opcional al cambiar el estado
  final String changedBy; // userId o 'system'

  const StatusHistoryEntry({
    required this.status,
    required this.changedAt,
    this.comment,
    this.changedBy = 'system',
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> j) =>
      StatusHistoryEntry(
        status: IncidentStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => IncidentStatus.pending,
        ),
        changedAt: DateTime.parse(j['changedAt'] as String),
        comment: j['comment'] as String?,
        changedBy: j['changedBy'] as String? ?? 'system',
      );

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'changedAt': changedAt.toIso8601String(),
    'comment': comment,
    'changedBy': changedBy,
  };

  String get statusLabel => switch (status) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };
}

// ── Comentario de un usuario ──────────────────────────────────────────────
class IncidentComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const IncidentComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory IncidentComment.fromJson(Map<String, dynamic> j) => IncidentComment(
    id: j['id'] as String,
    userId: j['userId'] as String,
    userName: j['userName'] as String,
    text: j['text'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ── Modelo principal ──────────────────────────────────────────────────────
class IncidentModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String? imageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<StatusHistoryEntry> statusHistory;
  final List<IncidentComment> comments;

  const IncidentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.priority = IncidentPriority.medium,
    this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.statusHistory = const [],
    this.comments = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    status: IncidentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => IncidentStatus.pending,
    ),
    priority: IncidentPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => IncidentPriority.medium,
    ),
    imageUrl: json['imageUrl'] as String?,
    address: json['address'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
        .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    comments: (json['comments'] as List<dynamic>? ?? [])
        .map((e) => IncidentComment.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'category': category,
    'status': status.name,
    'priority': priority.name,
    'imageUrl': imageUrl,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    'comments': comments.map((e) => e.toJson()).toList(),
  };

  IncidentModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<StatusHistoryEntry>? statusHistory,
    List<IncidentComment>? comments,
  }) => IncidentModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    imageUrl: imageUrl ?? this.imageUrl,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    statusHistory: statusHistory ?? this.statusHistory,
    comments: comments ?? this.comments,
  );

  // ── Helpers de presentación ─────────────────────────────────────────────
  String get statusLabel => switch (status) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };

  String get priorityLabel => switch (priority) {
    IncidentPriority.low => 'Baja',
    IncidentPriority.medium => 'Media',
    IncidentPriority.high => 'Alta',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IncidentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
