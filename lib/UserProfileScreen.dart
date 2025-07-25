import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _profileImageUrl = "";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _usernameController.text = userDoc["username"] ?? "";
          _emailController.text = userDoc["email"] ?? "";
          _emergencyContactController.text = userDoc["emergency_contact"] ?? "";
          _profileImageUrl = userDoc["profile_image"] ?? "";
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(File image) async {
    User? user = _auth.currentUser;
    if (user != null) {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
    return null;
  }

  void _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String? imageUrl = _profileImageUrl; // Keep existing profile image

        // Upload new image if selected
        if (_image != null) {
          imageUrl = await _uploadProfileImage(_image!);
        }

        await _firestore.collection('users').doc(user.uid).set({
          'username': _usernameController.text,
          'email': _emailController.text,
          'emergency_contact': _emergencyContactController.text,
          'profile_image': imageUrl, // Ensure profile image is updated
        }, SetOptions(merge: true));

        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text);
        }

        // Update UI with new profile data
        setState(() {
          _profileImageUrl = imageUrl ?? _profileImageUrl;
          _image = null; // Reset selected image
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (_profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl) as ImageProvider
                        : null),
                child: _image == null && _profileImageUrl.isEmpty
                    ? Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // Prevents changing email
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            TextField(
              controller: _emergencyContactController,
              decoration: InputDecoration(labelText: "Emergency Contact"),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            _isSaving
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text("Save Changes"),
                  ),
          ],
        ),
      ),
    );
  }
}
