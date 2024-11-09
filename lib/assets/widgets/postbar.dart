import 'package:flutter/material.dart';

class PostBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            color: Color(0xFF4EC8F4),
            onPressed: () {
              // Handle post action
            },
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Post something...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
