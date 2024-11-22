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

  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final conn = await MySqlConnection.connect(connSettings);
      Uint8List? profilePicData;
      if (_selectedImage != null) {
        profilePicData = await _selectedImage!.readAsBytes();
      }

      final updateQuery = profilePicData != null
          ? '''
            UPDATE users 
            SET username = ?, bio = ?, profile_pic = ?
            WHERE user_id = ?
            '''
          : '''
            UPDATE users 
            SET username = ?, bio = ?
            WHERE user_id = ?
            ''';

      final params = profilePicData != null
          ? [
              _usernameController.text,
              _bioController.text,
              profilePicData,
              widget.userId
            ]
          : [_usernameController.text, _bioController.text, widget.userId];

      await conn.query(updateQuery, params);

      await conn.close();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
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
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
