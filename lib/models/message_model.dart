class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? receiverId; // Can be null if it's a group chat or system message
  final String messageContent;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.receiverId,
    required this.messageContent,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String?,
      messageContent: json['message_content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_content': messageContent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  Message copyWith({
    String? chatId,
    String? senderId,
    String? receiverId,
    String? messageContent,
    DateTime? createdAt,
  }) {
    return Message(
      id: this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageContent: messageContent ?? this.messageContent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 