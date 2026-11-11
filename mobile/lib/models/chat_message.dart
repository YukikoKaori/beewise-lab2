class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.role,
    required this.body,
    required this.createdAt,
    this.kind = 'text',
    this.payload = const {},
    this.delivery = 'delivered',
  });

  final String id;
  final String senderId;
  final String senderName;
  final String role;
  final String body;
  final DateTime createdAt;
  final String kind;
  final Map<String, dynamic> payload;
  final String delivery;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        senderId: map['senderId'] as String? ?? '',
        senderName: map['senderName'] as String? ?? '',
        role: map['role'] as String? ?? 'system',
        body: map['body'] as String? ?? '',
        createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
        kind: map['kind'] as String? ?? 'text',
        payload: map['payload'] is Map<String, dynamic>
            ? map['payload'] as Map<String, dynamic>
            : const {},
        delivery: map['delivery'] as String? ?? 'delivered',
      );
}
