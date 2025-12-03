import 'user_model.dart';
class Message {
  final int idMessage;
  final String contenu;
  final DateTime dateEnvoi;
  final int idSender;
  final int idReceiver;
  final int idConversation;
  final bool isLu;
  final User sender;

  Message({
    required this.idMessage,
    required this.contenu,
    required this.dateEnvoi,
    required this.idSender,
    required this.idReceiver,
    required this.idConversation,
    required this.isLu,
    required this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      idMessage: json['id_message'],
      contenu: json['contenu'],
      dateEnvoi: DateTime.parse(json['date_envoi']),
      idSender: json['id_sender'],
      idReceiver: json['id_receiver'],
      idConversation: json['id_conversation'],
      isLu: json['is_lu'],
      sender: User.fromJson(json['sender']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
      'id_receiver': idReceiver,
      'id_conversation': idConversation,
    };
  }
}