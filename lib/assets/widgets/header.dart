import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:socialhub/components/profile/editprofile.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final String userId;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLogout;

  const Header({
    Key? key,
    required this.userId,
    this.onEditProfile,
    this.onLogout,
  }) : super(key: key);

  @override
  _HeaderState createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

class _HeaderState extends State<Header> {
  Uint8List? profilePicBytes;
  Map<String, dynamic> _userDetails = {};

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
    print('Header widget initialized.');
    _fetchProfilePicture();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    print('Loading user details...');
    try {
      final conn = await MySqlConnection.connect(connSettings);
      print('Database connection established.');

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
        print('User details fetched: $user');
        Uint8List? profileBytes;

        var profileBlob = user['profile_pic'];
        if (profileBlob != null) {
          if (profileBlob is Blob) {
            profileBytes = Uint8List.fromList(profileBlob.toBytes());
          } else if (profileBlob is List<int>) {
            profileBytes = Uint8List.fromList(profileBlob);
          }
        }

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
        }

        String _convertBlobToString(dynamic blob) {
          if (blob == null) return '';
          if (blob is Blob) return String.fromCharCodes(blob.toBytes());
          if (blob is List<int>) return String.fromCharCodes(blob);
          if (blob is String) return blob;
          throw Exception('Unexpected data type for bio: ${blob.runtimeType}');
        }

        if (mounted) {
          setState(() {
            _userDetails = {
              'username': user['username'],
              'email': user['email'],
              'bio': _convertBlobToString(user['bio']),
              'created_at': formattedDate,
              'course_code': user['course_code'],
            };
            profilePicBytes = profileBytes;
          });
          print('User details updated in state: $_userDetails');
        }
      } else {
        print('No user details found for userId: ${widget.userId}');
      }

      await conn.close();
      print('Database connection closed.');
    } catch (e) {
      print('Error loading user details: $e');
    }
  }

  Future<void> _fetchProfilePicture() async {
    print('Fetching profile picture...');
    try {
      final conn = await MySqlConnection.connect(connSettings);
      print('Database connection established.');

      var results = await conn.query(
        '''
        SELECT profile_pic 
        FROM users 
        WHERE user_id = ?
        ''',
        [widget.userId],
      );

      if (results.isNotEmpty) {
        var profileBlob = results.first['profile_pic'];
        Uint8List? profileBytes;

        if (profileBlob is Blob) {
          profileBytes = Uint8List.fromList(profileBlob.toBytes());
        } else if (profileBlob is List<int>) {
          profileBytes = Uint8List.fromList(profileBlob);
        }

        if (mounted) {
          setState(() {
            profilePicBytes = profileBytes;
          });
          print('Profile picture updated.');
        }
      } else {
        print('No profile picture found for userId: ${widget.userId}');
      }

      await conn.close();
      print('Database connection closed.');
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building Header widget...');
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.0,
      titleSpacing: 0.0,
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            children: [
              TextSpan(
                text: 'Social',
                style: TextStyle(
                  color: Color(0xFF4EC8F4),
                ),
              ),
              TextSpan(
                text: 'HUB',
                style: TextStyle(
                  color: Color(0xFF00364D),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _showProfileOptions(context),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: profilePicBytes != null
                  ? MemoryImage(profilePicBytes!) as ImageProvider<Object>
                  : const AssetImage('lib/assets/images/default_avatar.png')
                      as ImageProvider<Object>,
              radius: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileOptions(BuildContext context) {
    print('Showing profile options...');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Profile Options',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onEditProfile != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                              userId: int.parse(widget.userId))),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4EC8F4),
                  ),
                ),
              const SizedBox(height: 10),
              if (widget.onLogout != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onLogout!();
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf44e4e),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
