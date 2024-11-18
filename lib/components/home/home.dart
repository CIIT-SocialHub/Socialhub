import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/assets/widgets/navigation.dart';
import 'package:socialhub/assets/widgets/postbar.dart';
import 'dart:convert';
import 'dart:io';

// Function to convert BLOB to String (assuming UTF-8 encoding)
String blobToString(dynamic blobData) {
  if (blobData is List<int>) {
    return utf8.decode(blobData);
  } else {
    return blobData.toString();
  }
}

class HomePage extends StatefulWidget {
  final int userId;
  final String username;

  const HomePage({Key? key, required this.userId, required this.username})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _posts = [];

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
    _loadPosts();
  }

  // Fetch posts from the database
  Future<void> _loadPosts() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Updated query to include the username
      var results = await conn.query('''
  SELECT posts.post_id, posts.user_id, posts.content, posts.timestamp, 
         posts.visibility, posts.like_count, posts.comment_count, users.username, posts.media_url
  FROM posts 
  JOIN users ON posts.user_id = users.user_id 
  ORDER BY posts.timestamp DESC
''');

      // Map results to a list of posts
      setState(() {
        _posts = results.map((row) {
          return {
            'post_id': row[0],
            'user_id': row[1],
            'content': blobToString(row[2]),
            'media_url': row[8],
            'timestamp': row[3],
            'visibility': row[4],
            'like_count': row[5],
            'comment_count': row[6],
            'username': row[7],
          };
        }).toList();
      });

      // Close the connection
      await conn.close();
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  // Function to handle the like button press
  Future<void> _incrementLikeCount(int postId, int currentLikeCount) async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Update the like count in the database
      var result = await conn.query(
        'UPDATE posts SET like_count = ? WHERE post_id = ?',
        [currentLikeCount + 1, postId],
      );

      // Check if the update was successful
      if (result.affectedRows != null && result.affectedRows! > 0) {
        // If successful, update the UI
        setState(() {
          // Find the post and update the like count locally
          final postIndex =
              _posts.indexWhere((post) => post['post_id'] == postId);
          if (postIndex != -1) {
            _posts[postIndex]['like_count'] = currentLikeCount + 1;
          }
        });
      }

      // Close the connection
      await conn.close();
    } catch (e) {
      print('Error updating like count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}!'),
      ),
      body: Column(
        children: [
          // PostBar Widget for creating a post
          PostBar(
            refreshFeed: _loadPosts,
            userId: widget.userId,
          ),

          // Display the posts
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Display the username or Anonymous (for visibility)
                        Text(
                          post['visibility'] == 'anonymous'
                              ? 'Anonymous'
                              : post['username'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        // Display the content of the post
                        Text(post['content']),
                        const SizedBox(height: 10),
                        // Display the Image
                        post['media_url'] != null
                            ? post['media_url'].startsWith(
                                    'http') // Check if the URL is a network URL
                                ? Image.network(
                                    post['media_url']) // Load network image
                                : Image.file(File(
                                    post['media_url'])) // Load local image file
                            : Container(), // If no media URL, display an empty container
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            // Like button (like count)
                            IconButton(
                              icon: const Icon(Icons.thumb_up),
                              onPressed: () {
                                // Increment like count when button is pressed
                                _incrementLikeCount(
                                    post['post_id'], post['like_count']);
                              },
                            ),
                            Text('${post['like_count']}'),
                            const SizedBox(width: 20),
                            // Comment button (comment count)
                            const Icon(Icons.comment),
                            Text('${post['comment_count']} comments'),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
}
