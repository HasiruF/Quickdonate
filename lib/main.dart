import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'registration_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Request permission for iOS (if you plan to support iOS)
  await messaging.requestPermission();
  
  // Get FCM token (you can store this token in Firestore to send notifications later)
  String? token = await messaging.getToken();
  print("FCM Token: $token");
  
  // Set up foreground notification handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received message: ${message.notification?.title}, ${message.notification?.body}');
    // You can handle foreground notifications here (e.g., showing a dialog or updating UI)
  });

  // Set up background notification handler
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification clicked: ${message.notification?.title}');
    // You can handle background notifications here (e.g., navigate to a specific screen)
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return HomePage(userId: snapshot.data!.uid);
        }
        // If not logged in
        return LoginPage();
      },
    );
  }
}
