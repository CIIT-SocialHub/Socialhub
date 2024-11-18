import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/components/message/chats/chat.dart';
import 'dart:convert';

import '../../assets/widgets/navigation.dart'; // For utf8.decode

class MessagePage extends StatefulWidget {
  final int currentUserId;

  const MessagePage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      // Connect to the database
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '10.0.2.2', // Android emulator, or device IP
        port: 3306,
        db: 'socialhub',
        user: 'flutter',
        password: 'flutter',
      ));

      // Execute the query
      final results = await conn.query('''
        SELECT 
          CASE 
            WHEN sender_id = ? THEN receiver_id
            ELSE sender_id
          END AS user_id,
          (SELECT username FROM users WHERE user_id = 
            CASE 
              WHEN sender_id = ? THEN receiver_id
              ELSE sender_id
            END) AS username,
          MAX(message_text) AS last_message,
          MAX(timestamp) AS last_message_time
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY user_id
        ORDER BY last_message_time DESC;
    ''', [
        widget.currentUserId,
        widget.currentUserId,
        widget.currentUserId,
        widget.currentUserId,
      ]);

      // Process results
      List<Map<String, dynamic>> loadedMessages = [];
      for (var row in results) {
        // Check if the message is a Blob (binary data)
        var lastMessage = row['last_message'];

        // If it's a Blob, convert it to a List<int> and decode
        String messageText = '';
        if (lastMessage is List<int>) {
          messageText = utf8.decode(lastMessage);
        } else {
          messageText = lastMessage.toString();
        }

        loadedMessages.add({
          'user_id': row['user_id'],
          'username': row['username'] ?? 'Unknown User',
          'last_message': messageText,
          'last_message_time': row['last_message_time']?.toString() ?? '',
        });
      }

      // Close the connection
      await conn.close();

      // Update state
      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
    } catch (e) {
      // Handle errors
      print('Error fetching messages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
              ? const Center(child: Text('No messages to display.'))
              : ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          message['username']?[0].toUpperCase() ?? 'U',
                        ),
                      ),
                      title: Text(message['username']),
                      subtitle: Text(message['last_message']),
                      trailing: Text(
                        message['last_message_time'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      // Inside your ListView or where you display the messages
                      onTap: () {
                        // Navigate to chat screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              currentUserId: widget
                                  .currentUserId, // Assuming this is the current user ID
                              chatUserId: message[
                                  'user_id'], // The user ID of the person you're chatting with
                              chatUserName: message[
                                  'username'], // The username of the chat partner
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final int currentUserId;
  final int chatUserId;
  final String chatUserName;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.chatUserId,
    required this.chatUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $chatUserName'),
      ),
      body: const Center(
        child: Text('Chat functionality coming soon!'),
      ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
}
