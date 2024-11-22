import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
    SELECT users.username, users.email, users.profile_pic, users.bio, users.created_at, courses.course_code 
    FROM users
    JOIN courses ON users.course_id = courses.id
    WHERE users.user_id = ?
    ''',
        [widget.userId],
      );

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
          } else {
            print(
                'Unexpected profile_pic data type: ${profileBlob.runtimeType}');
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
        } else {
          print('Unhandled created_at format: ${createdAt.runtimeType}');
        }

        String _convertBlobToString(dynamic blob) {
          if (blob == null) {
            return ''; // Default to empty string if bio is null
          } else if (blob is Blob) {
            return String.fromCharCodes(blob.toBytes());
          } else if (blob is List<int>) {
            return String.fromCharCodes(blob);
          } else if (blob is String) {
            return blob; // Already a String
          } else {
            throw Exception(
                'Unexpected data type for bio: ${blob.runtimeType}');
          }
        }

        setState(() {
          _userDetails = {
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00509E),
                          Color.fromRGBO(78, 200, 244, 1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
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
                                      'assets/images/default_avatar.png')
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
                  // Information Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6.0,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileDetail(
                              icon: Icons.email,
                              title: 'Email',
                              subtitle: _userDetails['email'] ?? 'N/A',
                            ),
                            const Divider(),
                            _buildProfileDetail(
                              icon: Icons.info,
                              title: 'Bio',
                              subtitle:
                                  _userDetails['bio'] ?? 'No bio available',
                            ),
                            const Divider(),
                            _buildProfileDetail(
                              icon: Icons.calendar_today,
                              title: 'Joined On',
                              subtitle: _userDetails['created_at'] ?? 'Unknown',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Edit Profile Button
                ],
              ),
            ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }
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
        color: Colors.grey[700],
      ),
      const SizedBox(width: 12.0),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
