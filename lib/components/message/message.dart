import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/components/message/chats/chat.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../assets/widgets/navigation.dart';

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
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '10.0.2.2',
        port: 3306,
        db: 'socialhub',
        user: 'flutter',
        password: 'flutter',
      ));

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
          (SELECT profile_pic FROM users WHERE user_id = 
            CASE 
              WHEN sender_id = ? THEN receiver_id
              ELSE sender_id
            END) AS profile_pic,
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
        widget.currentUserId,
      ]);

      List<Map<String, dynamic>> loadedMessages = [];
      for (var row in results) {
        var lastMessage = row['last_message'];

        String messageText = '';
        if (lastMessage is List<int>) {
          messageText = utf8.decode(lastMessage);
        } else {
          messageText = lastMessage.toString();
        }

        Uint8List? profilePicBytes;
        if (row['profile_pic'] != null && row['profile_pic'] is Blob) {
          profilePicBytes =
              Uint8List.fromList((row['profile_pic'] as Blob).toBytes());
        }

        loadedMessages.add({
          'user_id': row['user_id'],
          'username': row['username'] ?? 'Unknown User',
          'profile_pic': profilePicBytes,
          'last_message': messageText,
          'last_message_time': row['last_message_time']?.toString() ?? '',
        });
      }

      await conn.close();

      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
    } catch (e) {
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
                    final profilePic = message['profile_pic'];

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: profilePic != null
                            ? MemoryImage(profilePic)
                            : const AssetImage(
                                    'lib/assets/images/default_avatar.png')
                                as ImageProvider,
                      ),
                      title: Text(message['username']),
                      subtitle: Text(message['last_message']),
                      trailing: Text(
                        message['last_message_time'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              currentUserId: widget.currentUserId,
                              chatUserId: message['user_id'],
                              chatUserName: message['username'],
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
