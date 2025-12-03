import 'user_model.dart';

class Conversation {
  final int idConversation;
  final int idUser1;
  final int idUser2;
  final DateTime? lastMessageDate;
  final String? lastMessageContent;
  final User otherUser;
  final int unreadCount;

  Conversation({
    required this.idConversation,
    required this.idUser1,
    required this.idUser2,
    this.lastMessageDate,
    this.lastMessageContent,
    required this.otherUser,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      idConversation: json['id_conversation'],
      idUser1: json['id_user1'],
      idUser2: json['id_user2'],
      lastMessageDate: json['last_message_date'] != null 
          ? DateTime.parse(json['last_message_date']) 
          : null,
      lastMessageContent: json['last_message_content'],
      otherUser: User.fromJson(json['other_user']),
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_conversation': idConversation,
      'id_user1': idUser1,
      'id_user2': idUser2,
      'last_message_date': lastMessageDate?.toIso8601String(),
      'last_message_content': lastMessageContent,
      'other_user': otherUser.toJson(),
      'unread_count': unreadCount,
    };
  }
}