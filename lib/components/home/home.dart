import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:socialhub/assets/widgets/navigation.dart';
import 'package:socialhub/assets/widgets/postbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Social',
                    style: TextStyle(
                      color: Color(0xFF4EC8F4),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextSpan(
                    text: 'HUB',
                    style: TextStyle(
                      color: Color(0xFF00364D),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Color(0xFF4EC8F4)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.account_circle_outlined,
                      color: Color(0xFF00364D)),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(child: NewsFeed()),
              ],
            ),
          ),
          PostBar(),
        ],
      ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
}

class PostInputWidget extends StatefulWidget {
  const PostInputWidget({super.key});

  @override
  _PostInputWidgetState createState() => _PostInputWidgetState();
}

class _PostInputWidgetState extends State<PostInputWidget> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  bool _isAnonymous = false;

  // Function to pick image from gallery or camera
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitPost() {
    // Logic to submit the post with text, image, and anonymous flag
    if (_postController.text.isNotEmpty || _selectedImage != null) {
      final post = Post(
        username: _isAnonymous
            ? 'Anonymous'
            : 'User Name', // Replace 'User Name' with the actual user's profile
        content: _postController.text,
        reactions: 0,
        comments: [],
        imageUrl: _selectedImage?.path,
        isAnonymous: _isAnonymous,
      );
      // Add post to the list of posts (backend or local state)
      // For now, we'll just print the post for demo purposes.
      print("Post submitted: ${post.content}, Anonymous: ${post.isAnonymous}");
      if (_selectedImage != null) {
        print("Post contains an image: ${_selectedImage!.path}");
      }
      _postController.clear();
      setState(() {
        _selectedImage = null;
        _isAnonymous = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _postController,
            decoration: InputDecoration(
              hintText: 'What’s on your mind?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Add Image'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _submitPost,
                child: const Text('Post'),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
              ),
              const Text('Post anonymously'),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              height: 150,
              width: 150,
            ), // Preview of the selected image
        ],
      ),
    );
  }
}

// Widget for displaying the newsfeed (list of posts)
class NewsFeed extends StatelessWidget {
  final List<Post> posts = [
    Post(
      username: 'John Doe',
      content: 'Just finished my final project for the semester!',
      reactions: 5,
      comments: ['Great job!', 'Wow, looks awesome!'],
      imageUrl: null,
      isAnonymous: false,
    ),
    Post(
      username: 'Anonymous',
      content: 'Looking forward to the next event at CIIT!',
      reactions: 12,
      comments: ['Me too!', 'Can’t wait!'],
      imageUrl: 'https://images.unsplash.com/photo-1583508915901-b5f84c1dcde1',
      isAnonymous: true, // Marked as an anonymous post
    ),
    // Add more sample posts here
  ];

  NewsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostWidget(post: posts[index]);
      },
    );
  }
}

// Data model for a Post
class Post {
  final String username;
  final String content;
  final int reactions;
  final List<String> comments;
  final String? imageUrl;
  final bool isAnonymous;

  Post({
    required this.username,
    required this.content,
    required this.reactions,
    required this.comments,
    this.imageUrl,
    this.isAnonymous = false,
  });
}

// Widget to display an individual post
class PostWidget extends StatelessWidget {
  final Post post;

  const PostWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              post.isAnonymous
                  ? 'Anonymous'
                  : post.username, // Hide username if post is anonymous
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(post.content),
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Image.network(post.imageUrl!),
              ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    // Logic for handling reactions (like)
                  },
                ),
                Text('${post.reactions}'),
                const SizedBox(width: 20),
                const Icon(Icons.comment),
                Text('${post.comments.length} comments'),
              ],
            ),
            const Divider(),
            // Displaying comments
            for (var comment in post.comments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('- $comment'),
              ),
          ],
        ),
      ),
    );
  }
}
