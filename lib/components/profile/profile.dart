import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/assets/widgets/navigation.dart';
import 'package:socialhub/components/profile/editprofile.dart';
import 'dart:io';

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
  Map<String, dynamic> _userDetails = {};
  Uint8List? profilePicBytes;

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
  }

  Future<void> _loadUserDetails() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);
      var results = await conn.query(
        '''
      SELECT username, email, profile_pic, bio, created_at
      FROM users
      WHERE user_id = ?
      ''',
        [widget.userId],
      );

      if (results.isNotEmpty) {
        var user = results.first;

        Uint8List? profileBytes;

        // Handle Blob conversion
        var profileBlob = user['profile_pic'];
        if (profileBlob != null) {
          if (profileBlob is Blob) {
            profileBytes = Uint8List.fromList(profileBlob.toBytes());
          } else {
            print(
                'Unexpected profile_pic data type: ${profileBlob.runtimeType}');
          }
        }

        print('Fetched profile_pic bytes: ${profileBytes?.length}');

        setState(() {
          _userDetails = {
            'username': user['username'],
            'email': user['email'],
            'bio': user['bio'],
            'created_at': user['created_at'],
          };
          profilePicBytes = profileBytes; // Update profile picture
        });
      } else {
        print('No user found for ID ${widget.userId}');
      }

      await conn.close();
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}\'s Profile'),
      ),
      body: _userDetails.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Profile Picture
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePicBytes != null
                          ? MemoryImage(profilePicBytes!)
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Display Username
                  Text(
                    _userDetails['username'] ?? widget.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display Email
                  Text('Email: ${_userDetails['email'] ?? 'N/A'}'),
                  const SizedBox(height: 10),
                  // Display Bio
                  Text(
                    'Bio: ${_userDetails['bio'] ?? 'No bio available'}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Display Join Date
                  Text('Joined on: ${_userDetails['created_at'] ?? 'Unknown'}'),
                  const SizedBox(height: 20),
                  // Edit Profile Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/editprofile',
                        arguments: widget.userId,
                      ).then((_) {
                        // Refresh profile details after returning from EditProfilePage
                        _loadUserDetails();
                      });
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
}
