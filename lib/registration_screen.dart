import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _usernameController = TextEditingController();
  final _lastnameController = TextEditingController(); 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<String> _deviceEmails = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _fetchDeviceEmails();
  }

  /// Fetch email addresses signed in on the device
  Future<void> _fetchDeviceEmails() async {
    try {
      List<GoogleSignInAccount?> googleAccounts =
          await Future.wait([_googleSignIn.signInSilently()]);

      setState(() {
        _deviceEmails = googleAccounts
            .where((account) => account != null)
            .map((account) => account!.email)
            .toList();
      });

      print("Fetched device emails: $_deviceEmails");
    } catch (e) {
      print("Error fetching device emails: $e");
    }
  }

  /// Email validation 
  Future<bool> _validateEmail(String email) async {
    if (!EmailValidator.validate(email)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid email format')));
      return false;
    }

    final validDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
      'zoho.com'
    ];
    String domain = email.split('@').last.toLowerCase();

    if (!validDomains.contains(domain)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please use a valid email provider')));
      return false;
    }

    try {
      var signInMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Email is already registered')));
        return false;
      }

      return true;
    } catch (e) {
      print("Email validation error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error validating email')));
      return false;
    }
  }

  /// Register the user
  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        bool isValidEmail = await _validateEmail(email);
        if (!isValidEmail) {
          setState(() => _isLoading = false);
          return;
        }

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
                email: email, password: password);
        String uid = userCredential.user!.uid;

        String? fcmToken = await FirebaseMessaging.instance.getToken();

        
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': _usernameController.text.trim(),
          'lastname': _lastnameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'usertype': "Client",
          'fcmToken': fcmToken,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful!')));

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage(userId: uid)));

      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Registration failed';

        if (e.code == 'email-already-in-use') {
          errorMessage = 'Email is already registered';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak';
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        print('Unexpected registration error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Enter your first name' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _lastnameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Enter your last name' : null,
              ),
              SizedBox(height: 10),
              if (_deviceEmails.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select from your device emails:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      hint: Text('Choose an email from this device'),
                      items: _deviceEmails.map((email) {
                        return DropdownMenuItem(
                          value: email,
                          child: Text(email, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (selectedEmail) {
                        if (selectedEmail != null) {
                          setState(() {
                            _emailController.text = selectedEmail;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    Text('Or enter a new email:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: _deviceEmails.isEmpty ? 'Enter email' : 'Alternative email'),
                validator: (value) => value!.isEmpty ? 'Enter an email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Enter a phone number' : null,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _register, child: Text('Register')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
