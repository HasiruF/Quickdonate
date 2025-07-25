import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'UserProfileScreen.dart';



class HomePage extends StatefulWidget {
  final String userId;

  HomePage({required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  String userEmail = '';
  String userType = '';

  //selected tab
  int _currentIndex = 0;

  //tab navigtion bar
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    _pages = [
      UserDonationsPage(userId: widget.userId),
      CampaignListPage(userId: widget.userId),
      ProfilePage(),
    ];
  }

  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Welcome, $userName',
        ),
        actions: [
          // Sign out button in the AppBar
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              // Sign out the user
              await FirebaseAuth.instance.signOut();

              // Navigate back to the login page after sign out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Current selected index
        onTap: _onTabTapped, // Update selected tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism), // Hand with heart
            label: 'My Donations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign), // Campaign/loudspeaker
            label: 'Browse Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = "";
  String email = "";
  String emergencyContact = "";
  String profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        username = userDoc["username"] ?? "";
        email = userDoc["email"] ?? "";
        emergencyContact = userDoc["emergency_contact"] ?? "";
        profileImageUrl = userDoc["profile_image"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            SizedBox(height: 10),
            Text("Username: $username", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Email: $email", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Emergency Contact: $emergencyContact",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfileScreen()),
                ).then((_) => _loadUserProfile());
              },
              child: Text("Edit Profile"),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDonationsPage extends StatelessWidget {
  final String userId;

  UserDonationsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Donations")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var donations = snapshot.data!.docs;

          if (donations.isEmpty) {
            return Center(child: Text("No donations yet."));
          }

          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              var donation = donations[index];
              return ListTile(
                title: Text("₹${donation['amount']}"),
                subtitle: Text("Campaign: ${donation['campaignId']}"),
                trailing: Text(
                  DateTime.fromMillisecondsSinceEpoch(donation['timestamp'].seconds * 1000)
                      .toString()
                      .split('.')[0],
                ),
              );
            },
          );
        },
      ),
    );
  }
}



class CampaignListPage extends StatelessWidget {
  final String userId;

  CampaignListPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Available Campaigns")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var campaigns = snapshot.data!.docs;

          if (campaigns.isEmpty) {
            return Center(child: Text("No campaigns available."));
          }

          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              var campaign = campaigns[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(campaign['title']),
                  subtitle: Text(campaign['description']),
                  trailing: ElevatedButton(
                    child: Text("Donate"),
                    onPressed: () {
                      
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
