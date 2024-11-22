import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
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

        setState(() {
          _userDetails = {
            'username': user['username'],
            'email': user['email'],
            'bio': user['bio'],
            'created_at':
                formattedDate, // Ensure created_at is formatted properly
            'course_code': user['course_code'], // Extract course_name here
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
      backgroundColor: const Color(0xFFF9F9F9), // Light background color
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
                        colors: [Color(0xFF00509E), Color(0xFF1A73E8)],
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        InfoCard(
                          icon: Icons.email,
                          label: 'Email',
                          value: _userDetails['email'] ?? 'N/A',
                        ),
                        // InfoCard(
                        //   icon: Icons.info_outline,
                        //   label: 'Bio',
                        //   value: _userDetails['bio'] ?? 'No bio available',
                        // ),
                        InfoCard(
                          icon: Icons.calendar_today,
                          label: 'Joined On',
                          value: _userDetails['created_at'] ?? 'Unknown',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Edit Profile Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/editprofile',
                        arguments: widget.userId,
                      ).then((_) => _loadUserDetails());
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00509E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/',
                        arguments: widget.userId,
                      ).then((_) => _loadUserDetails());
                    },
                    label: const Text(
                      'logout',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 194, 29, 29),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
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
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
