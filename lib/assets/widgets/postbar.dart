import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostBar extends StatefulWidget {
  final VoidCallback refreshFeed;
  final int userId;

  PostBar({required this.refreshFeed, required this.userId});

  @override
  _PostBarState createState() => _PostBarState();
}

class _PostBarState extends State<PostBar> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  final picker = ImagePicker();

  final connSettings = ConnectionSettings(
    host: '10.0.2.2',
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_postController.text.isEmpty && _selectedImage == null) return;

    try {
      final conn = await MySqlConnection.connect(connSettings);

      String imagePath = '';
      if (_selectedImage != null) {
        imagePath = _selectedImage!.path;
      }

      await conn.query(
        'INSERT INTO posts (user_id, content, timestamp, visibility, like_count, comment_count, media_url) VALUES (?, ?, NOW(), ?, ?, ?, ?)',
        [
          widget.userId,
          _postController.text,
          'public',
          0,
          0,
          imagePath,
        ],
      );

      await conn.close();

      setState(() {
        _postController.clear();
        _selectedImage = null;
      });

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
      child: Column(
        children: [
          if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              height: 150.0,
              width: 150.0,
              fit: BoxFit.cover,
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.add_circle_outline),
                color: Color(0xFF4EC8F4),
                onPressed: _submitPost,
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
                onPressed: _pickImage, // Pick image from gallery
              ),
            ],
          ),
        ],
      ),
    );
  }
}
