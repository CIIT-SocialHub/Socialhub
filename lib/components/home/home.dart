import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/assets/widgets/header.dart';
import 'package:socialhub/assets/widgets/navigation.dart';
import 'package:socialhub/assets/widgets/postbar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:timeago/timeago.dart' as timeago;

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
  final Map<int, TextEditingController> _commentControllers = {};
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

  Future<void> _loadPosts() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Fetch the most recent post of the logged-in user
      var recentUserPostResult = await conn.query('''
        SELECT posts.post_id, posts.user_id, posts.content, posts.timestamp,
               posts.visibility, posts.like_count, posts.comment_count, 
               users.username, posts.media_url, users.profile_pic
        FROM posts 
        JOIN users ON posts.user_id = users.user_id 
        WHERE posts.user_id = ? 
        ORDER BY posts.timestamp DESC
        LIMIT 1
      ''', [widget.userId]);

      Map<String, dynamic>? recentUserPost;
      if (recentUserPostResult.isNotEmpty) {
        var row = recentUserPostResult.first;
        recentUserPost = {
          'post_id': row['post_id'],
          'user_id': row['user_id'],
          'content': blobToString(row['content']),
          'media_url': row['media_url'],
          'timestamp': timeago.format(row['timestamp']),
          'visibility': row['visibility'],
          'like_count': row['like_count'],
          'comment_count': row['comment_count'],
          'username': row['username'],
          'profile_pic':
              row['profile_pic'] != null && row['profile_pic'] is Blob
                  ? Uint8List.fromList((row['profile_pic'] as Blob).toBytes())
                  : null,
          'comments': []
        };

        _commentControllers[row['post_id']] = TextEditingController();
      }

      // Fetch all other posts
      var results = await conn.query('''
        SELECT posts.post_id, posts.user_id, posts.content, posts.timestamp,
               posts.visibility, posts.like_count, posts.comment_count, 
               users.username, posts.media_url, users.profile_pic
        FROM posts 
        JOIN users ON posts.user_id = users.user_id 
        ORDER BY posts.timestamp DESC
      ''');

      List<Map<String, dynamic>> posts = [];
      for (var row in results) {
        // Skip adding the logged-in user's most recent post to avoid duplication
        if (recentUserPost != null &&
            row['post_id'] == recentUserPost['post_id']) {
          continue;
        }
        posts.add({
          'post_id': row['post_id'],
          'user_id': row['user_id'],
          'content': blobToString(row['content']),
          'media_url': row['media_url'],
          'timestamp': timeago.format(row['timestamp']),
          'visibility': row['visibility'],
          'like_count': row['like_count'],
          'comment_count': row['comment_count'],
          'username': row['username'],
          'profile_pic':
              row['profile_pic'] != null && row['profile_pic'] is Blob
                  ? Uint8List.fromList((row['profile_pic'] as Blob).toBytes())
                  : null,
          'comments': []
        });

        _commentControllers[row['post_id']] = TextEditingController();
      }

      // Combine the most recent user post with other posts
      setState(() {
        _posts = [];
        if (recentUserPost != null) {
          _posts.add(recentUserPost);
        }
        _posts.addAll(posts);
      });

      await conn.close();
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  Future<void> _loadComments(int postId, int postIndex) async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      var result = await conn.query('''
        SELECT comment_id, user_id, comment, timestamp 
        FROM comments WHERE post_id = ?
      ''', [postId]);

      List<Map<String, dynamic>> comments = [];
      for (var row in result) {
        comments.add({
          'comment_id': row['comment_id'],
          'user_id': row['user_id'],
          'content': blobToString(row['comment']),
          'timestamp': row['timestamp']
        });
      }

      setState(() {
        _posts[postIndex]['comments'] = comments;
      });

      await conn.close();
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _addComment(int postId, String commentContent) async {
    if (commentContent.isEmpty) return;

    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Convert DateTime to UTC
      final utcTimestamp = DateTime.now().toUtc();

      await conn.query('''
      INSERT INTO comments (post_id, user_id, comment, timestamp)
      VALUES (?, ?, ?, ?)
    ''', [postId, widget.userId, commentContent, utcTimestamp]);

      await conn.query('''
      UPDATE posts SET comment_count = comment_count + 1 WHERE post_id = ?
    ''', [postId]);

      final postIndex = _posts.indexWhere((post) => post['post_id'] == postId);
      if (postIndex != -1) {
        await _loadComments(postId, postIndex);
      }

      setState(() {
        _posts[postIndex]['comment_count']++;
      });

      _commentControllers[postId]?.clear();

      await conn.close();
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<void> _incrementLikeCount(int postId, int currentLikeCount) async {
    try {
      final conn = await MySqlConnection.connect(connSettings);
      var result = await conn.query(
        'UPDATE posts SET like_count = ? WHERE post_id = ?',
        [currentLikeCount + 1, postId],
      );

      if (result.affectedRows != null && result.affectedRows! > 0) {
        setState(() {
          final postIndex =
              _posts.indexWhere((post) => post['post_id'] == postId);
          if (postIndex != -1) {
            _posts[postIndex]['like_count'] = currentLikeCount + 1;
          }
        });
      }

      await conn.close();
    } catch (e) {
      print('Error updating like count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(userId: widget.userId.toString()),
      body: Column(
        children: [
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
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: post['profile_pic'] != null
                                  ? MemoryImage(post['profile_pic'])
                                  : const AssetImage(
                                          'lib/assets/images/default_avatar.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['visibility'] == 'anonymous'
                                      ? 'Anonymous'
                                      : post['username'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(
                                    height:
                                        4), // Space between username and timestamp
                                Text(
                                  post['timestamp'],
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(post['content']),
                        const SizedBox(height: 10),
                        if (post['media_url'] != null &&
                            post['media_url'].isNotEmpty)
                          post['media_url'].startsWith('http')
                              ? Image.network(post['media_url'])
                              : File(post['media_url']).existsSync()
                                  ? Image.file(File(post['media_url']))
                                  : Container(),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward_outlined),
                              onPressed: () {
                                _incrementLikeCount(
                                    post['post_id'], post['like_count']);
                              },
                            ),
                            Text('${post['like_count']}'),
                            const SizedBox(width: 20),
                            const Icon(Icons.comment),
                            Text('${post['comment_count']} comments'),
                          ],
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller:
                                      _commentControllers[post['post_id']],
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                  _addComment(
                                      post['post_id'],
                                      _commentControllers[post['post_id']]!
                                          .text);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Display Comments
                        if (post['comments'].isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: post['comments'].length,
                            itemBuilder: (context, commentIndex) {
                              final comment = post['comments'][commentIndex];
                              return ListTile(
                                title: Text(comment['content']),
                                subtitle: Text('By ${comment['user_id']}'),
                              );
                            },
                          ),
                        // Comment Input
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          PostBar(
            refreshFeed: _loadPosts,
            userId: widget.userId,
          ),
        ],
      ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
}
