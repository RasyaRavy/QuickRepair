class ReportModel {
  final String id;
  final String userId;
  final String? technicianId;
  final String title;
  final String description;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String location;
  // Possible status values: New, Assigned, In Progress, Completed, Cancelled
  final String status;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? reporterId;
  final String? reporterName;

  ReportModel({
    required this.id,
    required this.userId,
    this.technicianId,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.reporterId,
    this.reporterName,
  });

  // Create from Supabase response
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      userId: json['user_id'],
      technicianId: json['technician_id'],
      title: json['title'] ?? json['description'].toString().split('\n').first,
      description: json['description'],
      photoUrl: json['photo_url'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      location: json['location'] ?? 'Unknown location',
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      reporterId: json['reporter_id'],
      reporterName: json['reporter_name'],
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'title': title,
      'description': description,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'status': status,
      'assigned_at': assignedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'reporter_id': reporterId,
      'reporter_name': reporterName,
    };
  }

  // Create a copy with updated fields
  ReportModel copyWith({
    String? technicianId,
    String? title,
    String? description,
    String? photoUrl,
    String? location,
    String? status,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? reporterId,
    String? reporterName,
  }) {
    return ReportModel(
      id: this.id,
      userId: this.userId,
      technicianId: technicianId ?? this.technicianId,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: this.latitude,
      longitude: this.longitude,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
    );
  }
} 