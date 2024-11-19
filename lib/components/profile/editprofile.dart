import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;

  const EditProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _selectedImage;

  // MySQL connection settings
  final connSettings = ConnectionSettings(
    host: '10.0.2.2',
    port: 3306,
    db: 'socialhub',
    user: 'flutter',
    password: 'flutter',
  );

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDetails();
  }

  // Load current user details to pre-fill the form
  Future<void> _loadCurrentUserDetails() async {
    try {
      final conn = await MySqlConnection.connect(connSettings);
      var results = await conn.query(
        '''
        SELECT username, bio, profile_pic
        FROM users
        WHERE user_id = ?
        ''',
        [widget.userId],
      );

      if (results.isNotEmpty) {
        var user = results.first;

        setState(() {
          _usernameController.text = user[0] ?? '';
          _bioController.text = user[1] ?? '';
          if (user[2] != null && user[2] is List<int>) {
            _selectedImage = File.fromRawPath(Uint8List.fromList(user[2]));
          }
        });
      }

      await conn.close();
    } catch (e) {
      print('Error loading user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user details.')),
      );
    }
  }

  // Update user details in the database
  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final conn = await MySqlConnection.connect(connSettings);

      // Convert profile picture to binary data if selected
      Uint8List? profilePicData;
      if (_selectedImage != null) {
        profilePicData = await _selectedImage!.readAsBytes();
      }

      // Update query
      await conn.query(
        '''
        UPDATE users 
        SET username = ?, bio = ?, profile_pic = ?
        WHERE user_id = ?
        ''',
        [
          _usernameController.text,
          _bioController.text,
          profilePicData,
          widget.userId,
        ],
      );

      await conn.close();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context); // Return to ProfilePage
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Profile Picture
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : const AssetImage(
                                      'assets/images/default_avatar.png',
                                    ) as ImageProvider,
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 30),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.length > 150) {
                          return 'Bio cannot exceed 150 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Save Button
                    ElevatedButton(
                      onPressed: _updateUserProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
