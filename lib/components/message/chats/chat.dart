import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class ChatPage extends StatefulWidget {
  final int userId;
  final String username;

  const ChatPage({Key? key, required this.userId, required this.username})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  // MySQL connection settings
  final connSettings = ConnectionSettings(
    host: '10.0.2.2',
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // Fetch messages from the database
  Future<void> _loadMessages() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      var results = await conn.query(
        'SELECT sender_id, message, timestamp '
        'FROM messages '
        'WHERE sender_id = ? OR recipient_id = ? '
        'ORDER BY timestamp ASC',
        [widget.userId, widget.userId],
      );

      setState(() {
        _messages = results.map((row) {
          return {
            'sender_id': row[0],
            'message': row[1],
            'timestamp': row[2].toString().substring(0, 16),
          };
        }).toList();
      });

      await conn.close();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Send a new message
  Future<void> _sendMessage(String message) async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      await conn.query(
        'INSERT INTO messages (sender_id, recipient_id, message, timestamp) '
        'VALUES (?, ?, ?, NOW())',
        [widget.userId, widget.userId, message],
      );

      _messageController.clear();
      _loadMessages();

      await conn.close();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender_id'] == widget.userId;
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
                    child: Text(message['message']),
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
                      _sendMessage(_messageController.text.trim());
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
