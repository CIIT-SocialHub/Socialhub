import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostBar extends StatefulWidget {
  final VoidCallback refreshFeed; // Callback to refresh the feed
  final int userId; // Pass the user ID dynamically from login

  PostBar({required this.refreshFeed, required this.userId});

  @override
  _PostBarState createState() => _PostBarState();
}

class _PostBarState extends State<PostBar> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage; // To store the selected image
  final picker = ImagePicker(); // Image picker instance

  // MySQL connection settings
  final connSettings = ConnectionSettings(
    host: '10.0.2.2', // Use this for Android emulator, or your device IP
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Function to submit the post along with an image
  Future<void> _submitPost() async {
    if (_postController.text.isEmpty && _selectedImage == null) return;

    try {
      // Establish the connection
      final conn = await MySqlConnection.connect(connSettings);

      String imagePath = '';
      if (_selectedImage != null) {
        // Upload image logic here (you can use Firebase Storage or any other service)
        // For now, we'll use a placeholder image path for demonstration
        imagePath = _selectedImage!.path;
      }

      // Insert the post into the 'posts' table, including the image path
      await conn.query(
        'INSERT INTO posts (user_id, content, timestamp, visibility, like_count, comment_count, media_url) VALUES (?, ?, NOW(), ?, ?, ?, ?)',
        [
          widget.userId, // Use the passed user ID
          _postController.text,
          'public', // Example visibility setting
          0, // Initial like count
          0, // Initial comment count
          imagePath, // Store the image path (or upload URL)
        ],
      );

      // Close the connection
      await conn.close();

      // Clear the input field and image after submission
      setState(() {
        _postController.clear();
        _selectedImage = null;
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
      child: Column(
        children: [
          // Image preview if an image is selected
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
                onPressed: _pickImage, // Pick image from gallery
              ),
            ],
          ),
        ],
      ),
    );
  }
}
