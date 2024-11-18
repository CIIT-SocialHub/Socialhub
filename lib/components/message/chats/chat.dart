import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:convert'; // To decode binary data if necessary

class ChatPage extends StatefulWidget {
  final int currentUserId;
  final int chatUserId;
  final String chatUserName;

  const ChatPage({
    Key? key,
    required this.currentUserId,
    required this.chatUserId,
    required this.chatUserName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  // MySQL connection settings
  final connSettings = ConnectionSettings(
    host: '10.0.2.2', // Adjust this for real device or emulator
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  @override
  void initState() {
    super.initState();
    print(
        'Initializing chat for ${widget.chatUserName}'); // Debug: Log when chat page initializes
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      var results = await conn.query(
        '''
      SELECT sender_id, message_text, timestamp 
      FROM messages 
      WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?) 
      ORDER BY timestamp ASC''',
        [
          widget.currentUserId,
          widget.chatUserId,
          widget.chatUserId,
          widget.currentUserId,
        ],
      );

      print('Raw results: $results'); // Debug: Log raw results

      setState(() {
        _messages = results.map((row) {
          var message = row[1];

          // Debug: Check type of message
          print('Message type before processing: ${message.runtimeType}');

          // Decode Blob or List<int> to a string
          if (message is Blob) {
            message = utf8.decode(message.toBytes());
            print('Decoded Blob message: $message'); // Debug
          } else if (message is List<int>) {
            message = utf8.decode(message);
            print('Decoded List<int> message: $message'); // Debug
          } else {
            print('Unexpected message type: $message'); // Debug
          }

          return {
            'sender_id': row[0],
            'message_text': message,
            'timestamp': row[2].toString().substring(0, 16),
          };
        }).toList();
      });

      print('Processed messages: $_messages'); // Debug

      await conn.close();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Send a new message
  Future<void> _sendMessage(String message) async {
    try {
      print('Sending message: $message'); // Debug: Log the message being sent
      final conn = await MySqlConnection.connect(connSettings);

      await conn.query(
        'INSERT INTO messages (sender_id, receiver_id, message_text, timestamp) '
        'VALUES (?, ?, ?, NOW())',
        [widget.currentUserId, widget.chatUserId, message],
      );

      _messageController.clear();
      print(
          'Message sent. Reloading messages...'); // Debug: Log after sending message
      _loadMessages();

      await conn.close();
      print(
          'Connection closed after sending message'); // Debug: Log after closing connection
    } catch (e) {
      print(
          'Error sending message: $e'); // Debug: Log any error during sending message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender_id'] == widget.currentUserId;
                print(
                    'Displaying message from user ${message['sender_id']}'); // Debug: Log which user’s message is being displayed
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(message['message_text']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      print(
                          'Message text is not empty. Sending message...'); // Debug: Log when message is being sent
                      _sendMessage(_messageController.text.trim());
                    } else {
                      print(
                          'Message text is empty, not sending'); // Debug: Log if the message is empty
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
