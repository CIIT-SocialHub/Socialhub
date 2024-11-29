import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/assets/widgets/header.dart';
import 'package:socialhub/assets/widgets/navigation.dart';
import 'package:socialhub/components/profile/editprofile.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String username;

  const ProfilePage({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isFollowing = false;
  Map<String, dynamic> _userDetails = {};
  Uint8List? profilePicBytes;
  List<Map<String, dynamic>> suggestedUsers = [];

  // MySQL connection settings
  final connSettings = ConnectionSettings(
    host: '10.0.2.2', // Adjust host for emulator
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadSuggestedUsers();
  }

  Future<void> _loadUserDetails() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);
      var results = await conn.query('''
SELECT users.username, users.email, users.profile_pic, users.bio, users.created_at, courses.course_code, users.user_id
FROM users 
JOIN courses ON users.course_id = courses.id 
WHERE users.user_id = ? 
''', [widget.userId]);

      print('Query Result: $results');
      if (results.isNotEmpty) {
        var user = results.first;
        print('Fetched user: $user'); // Debug print to check the user data
        // Additional checks for user_id
        print('User ID: ${user['user_id']}');
      } else {
        print('No user found for ID ${widget.userId}');
      }

      print('Query Result: $results');

      if (results.isNotEmpty) {
        var user = results.first;
        Uint8List? profileBytes;

        // Handle profile picture BLOB (BLOB -> Uint8List)
        var profileBlob = user['profile_pic'];
        if (profileBlob != null) {
          if (profileBlob is Blob) {
            profileBytes = Uint8List.fromList(profileBlob.toBytes());
            print(
                'Fetched profile picture as Blob, size: ${profileBytes.length}');
          } else if (profileBlob is List<int>) {
            profileBytes = Uint8List.fromList(profileBlob);
            print(
                'Fetched profile picture as List<int>, size: ${profileBytes.length}');
          }
        }

        // Format created_at timestamp
        String formattedDate = '';
        var createdAt = user['created_at'];
        if (createdAt is DateTime) {
          formattedDate = DateFormat('MMMM d, yyyy').format(createdAt);
        } else if (createdAt is String) {
          try {
            DateTime parsedDate = DateTime.parse(createdAt);
            formattedDate = DateFormat('MMMM d, yyyy').format(parsedDate);
          } catch (e) {
            print('Error parsing date string: $e');
          }
        } else if (createdAt is List<int>) {
          try {
            String blobString = utf8.decode(createdAt);
            DateTime parsedDate = DateTime.parse(blobString);
            formattedDate = DateFormat('MMMM d, yyyy').format(parsedDate);
          } catch (e) {
            print('Error parsing created_at as List<int>: $e');
          }
        }

        setState(() {
          _userDetails = {
            'user_id': user['user_id'],
            'username': user['username'],
            'email': user['email'],
            'bio': _convertBlobToString(user['bio']), // Convert bio to string
            'created_at':
                formattedDate, // Ensure created_at is formatted properly
            'course_code': user['course_code'], // Extract course_code
          };
          profilePicBytes = profileBytes; // Store profile picture bytes
        });
        print('Fetched user details: $_userDetails');
      } else {
        print('No user found for ID ${widget.userId}');
      }

      await conn.close();
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<Uint8List> _getProfilePic(dynamic profilePic) async {
    if (profilePic != null) {
      if (profilePic is List<int>) {
        return Uint8List.fromList(profilePic);
      } else if (profilePic is Blob) {
        return Uint8List.fromList(profilePic.toBytes());
      }
    }
    // If no profile picture, return the default avatar
    return await loadImage('lib/assets/images/default_avatar.png');
  }

  Future<Uint8List> loadImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  Future<void> _loadSuggestedUsers() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Get users with the same course (80%)
      var sameCourseResults = await conn.query(
        '''
    SELECT users.username, users.profile_pic, users.course_id 
    FROM users
    WHERE users.course_id = (SELECT course_id FROM users WHERE user_id = ?)
    LIMIT 80
    ''',
        [widget.userId],
      );

      // Get users with different courses (20%)
      var otherCourseResults = await conn.query(
        '''
    SELECT users.username, users.profile_pic, users.course_id 
    FROM users
    WHERE users.course_id != (SELECT course_id FROM users WHERE user_id = ?)
    LIMIT 20
    ''',
        [widget.userId],
      );

      setState(() {
        suggestedUsers = [
          ...sameCourseResults.map((row) {
            return {
              'username': row['username'],
              'profile_pic': row['profile_pic'],
              'course_code': 'Same course',
            }.cast<String, dynamic>();
          }).toList(),
          ...otherCourseResults.map((row) {
            return {
              'username': row['username'],
              'profile_pic': row['profile_pic'],
              'course_code': 'Other course',
            }.cast<String, dynamic>();
          }).toList(),
        ];
      });

      await conn.close();
    } catch (e) {
      print('Error loading suggested users: $e');
    }
  }

  // Function to handle the follow logic
  Future<void> _followUser() async {
    try {
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: 'root',
        db: 'socialhub',
      ));

      // Insert the follow request into the database
      await conn.query('''
  INSERT INTO followers (user_id, follower_user_id, status)
  VALUES (?, ?, 'pending')
''', [widget.userId, widget.userId]);

      setState(() {
        isFollowing = true; // Update the button UI
      });

      await conn.close();

      // Feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow request sent successfully.')),
      );
    } catch (e) {
      print('Error following user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending follow request.')),
      );
    }
  }

  Future<void> _toggleFollowUser(int targetUserId) async {
    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Check if the current user is already following the target user
      var result = await conn.query(
        '''SELECT * FROM followers WHERE user_id = ? AND follower_user_id = ?''',
        [targetUserId, widget.userId],
      );

      if (result.isEmpty) {
        // Follow the user if no existing relationship
        await conn.query('''
        INSERT INTO followers (user_id, follower_user_id, status)
        VALUES (?, ?, 'pending')
      ''', [targetUserId, widget.userId]);
        setState(() {
          isFollowing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow request sent successfully.')),
        );
      } else {
        // Unfollow the user if already following
        await conn.query('''
        DELETE FROM followers WHERE user_id = ? AND follower_user_id = ?
      ''', [targetUserId, widget.userId]);
        setState(() {
          isFollowing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unfollowed the user.')),
        );
      }

      await conn.close();
    } catch (e) {
      print('Error toggling follow status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing follow request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(
        userId: widget.userId.toString(),
        onEditProfile: () {
          Navigator.pushNamed(context, '/editprofile').then((_) {});
        },
        onLogout: () {
          Navigator.pushNamed(context, '/');
        },
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: _userDetails.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Header Section
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(78, 200, 244, 1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: profilePicBytes != null
                              ? MemoryImage(profilePicBytes!)
                              : const AssetImage(
                                      'lib/assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _userDetails['username'] ?? widget.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _userDetails['course_code'] ?? widget.username,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text('Email'),
                              subtitle: Text(_userDetails['email'] ?? 'N/A'),
                            ),
                            ListTile(
                              title: Text('Bio'),
                              subtitle: Text(
                                  _userDetails['bio'] ?? 'No bio available'),
                            ),
                            ListTile(
                              title: Text('Joined On'),
                              subtitle:
                                  Text(_userDetails['created_at'] ?? 'Unknown'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Suggested Users Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suggested Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: suggestedUsers.length,
                          itemBuilder: (context, index) {
                            var user = suggestedUsers[index];

                            var userId =
                                user['user_id'] != null ? user['user_id'] : -1;
                            print('User ID: $userId');

                            // Check if the userId is valid before using it
                            return ListTile(
                              // leading: CircleAvatar(
                              //   radius: 30,
                              //   backgroundImage: user['profile_pic'] != null
                              //       ? MemoryImage(user['profile_pic'])
                              //       : const AssetImage(
                              //               'assets/images/default_avatar.png')
                              //           as ImageProvider,
                              // ),
                              title: Text(user['username'] ?? 'Unknown User'),
                              subtitle:
                                  Text(user['course_code'] ?? 'No Course'),
                              trailing: IconButton(
                                icon: Icon(isFollowing
                                    ? Icons.person_remove
                                    : Icons.person_add),
                                onPressed: () {
                                  if (userId != -1) {
                                    _toggleFollowUser(userId);
                                  } else {
                                    print('Invalid userId');
                                    print('User details: $user');
                                    print('Suggested Users: $suggestedUsers');
                                  }
                                },
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }

  Widget _buildProfileDetail({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.0,
          color: Colors.black,
        ),
        const SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Text(subtitle),
          ],
        ),
      ],
    );
  }

  String _convertBlobToString(dynamic blob) {
    if (blob == null) return '';
    if (blob is List<int>) {
      return utf8.decode(blob);
    } else if (blob is String) {
      return blob;
    }
    return '';
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00509E), size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
