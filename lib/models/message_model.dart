class MessageModel {
  final String id;
  final String reportId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.reportId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
  });

  // Create from Supabase response
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      reportId: json['report_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'sender_id': senderId,
      'content': content,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  // Create a copy with updated fields
  MessageModel copyWith({
    String? content,
    DateTime? editedAt,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: this.id,
      reportId: this.reportId,
      senderId: this.senderId,
      content: content ?? this.content,
      createdAt: this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
} 