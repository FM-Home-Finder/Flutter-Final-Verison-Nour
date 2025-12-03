import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../screens/chat_screen.dart';
import '../config/app_config.dart';

class ConversationItem extends StatelessWidget {
  final Conversation conversation;

  const ConversationItem({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.otherUser.photoProfil != null
            ? NetworkImage(AppConfig.getPhotoUrl(conversation.otherUser.photoProfil))
            : null,
        backgroundColor: conversation.otherUser.photoProfil != null 
            ? Colors.transparent 
            : Colors.blue,
        child: conversation.otherUser.photoProfil == null
            ? Text(
                conversation.otherUser.initials,
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(
        conversation.otherUser.fullName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        conversation.lastMessageContent ?? 'Aucun message',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (conversation.lastMessageDate != null)
            Text(
              _formatDate(conversation.lastMessageDate!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount > 9 ? '9+' : '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.idConversation,
              otherUserId: conversation.otherUser.idUser,
              otherUserName: conversation.otherUser.fullName,
              otherUserPhoto: conversation.otherUser.photoProfil,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
}