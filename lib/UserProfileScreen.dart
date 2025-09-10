import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';


class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSaving = false;

  File? _profileImage; // local image file

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocalImage();
  }

  /// Load Firestore user data
  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _usernameController.text = userDoc["username"] ?? "";
          _lastnameController.text = userDoc["lastname"] ?? "";
          _emailController.text = userDoc["email"] ?? "";
          _phoneController.text = userDoc["phone"] ?? "";
        });
      }
    }
  }

  /// Load local profile picture (if saved)
  Future<void> _loadLocalImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/profile_pic.png");
    if (await file.exists()) {
      setState(() {
        _profileImage = file;
      });
    }
  }

  /// Pick a new image and save locally
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File("${dir.path}/profile_pic.png");
      await File(pickedFile.path).copy(localFile.path);
      setState(() {
        _profileImage = localFile;
      });
    }
  }

  /// Save profile info to Firestore (not the picture)
  void _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          "username": _usernameController.text.trim(),
          "lastname": _lastnameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": _phoneController.text.trim(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile picture
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Text fields
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            TextField(
              controller: _lastnameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 20),

            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text("Save Changes"),
                  ),
          ],
        ),
      ),
    );
  }
}
