import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class PostBar extends StatefulWidget {
  final VoidCallback refreshFeed; // Callback to refresh the feed
  final int userId; // Pass the user ID dynamically from login

  PostBar({required this.refreshFeed, required this.userId});

  @override
  _PostBarState createState() => _PostBarState();
}

class _PostBarState extends State<PostBar> {
  final TextEditingController _postController = TextEditingController();

  // MySQL connection settings
  final connSettings = ConnectionSettings(
    host: '10.0.2.2', // Use this for Android emulator, or your device IP
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  Future<void> _submitPost() async {
    if (_postController.text.isEmpty) return;

    try {
      // Establish the connection
      final conn = await MySqlConnection.connect(connSettings);

      // Insert the post into the 'posts' table
      await conn.query(
        'INSERT INTO posts (user_id, content, timestamp, visibility, like_count, comment_count) VALUES (?, ?, NOW(), ?, ?, ?)',
        [
          widget.userId, // Use the passed user ID
          _postController.text,
          'public', // Example visibility setting
          0, // Initial like count
          0, // Initial comment count
        ],
      );

      // Close the connection
      await conn.close();

      // Clear the input field after submission
      setState(() {
        _postController.clear();
      });

      // Trigger the callback to refresh the feed
      widget.refreshFeed();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post submitted successfully!')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit post. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            color: Color(0xFF4EC8F4),
            onPressed: _submitPost, // Call _submitPost when pressed
          ),
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: 'Post something...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              // Optional: Add image upload functionality here
            },
          ),
        ],
      ),
    );
  }
}
