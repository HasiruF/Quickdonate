import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'UserProfileScreen.dart';
import 'add_campaign_screen.dart';
import 'donate_screen.dart';
import 'add_posts_screen.dart';
import 'view_post_screen.dart';

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
            icon: Icon(Icons.volunteer_activism),
            label: 'Donate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign), 
            label: 'My Campaigns',
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

class UserDonationsPage extends StatefulWidget {
  final String userId;

  UserDonationsPage({required this.userId});

  @override
  _UserDonationsPageState createState() => _UserDonationsPageState();
}

class _UserDonationsPageState extends State<UserDonationsPage> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Browse Campaigns")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search campaigns...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final campaigns = snapshot.data!.docs.where((doc) {
                  final title = doc['title'].toString().toLowerCase();
                  return title.contains(_searchText);
                }).toList();

                if (campaigns.isEmpty) {
                  return Center(child: Text("No matching campaigns."));
                }

                return ListView.builder(
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    final title = campaign['title'];
                    final description = campaign['description'];
                    final totalDonations = campaign['totalDonations'] ?? 0;
                    final goalAmount = campaign['goalAmount'] ?? 10000;

                    double progress = totalDonations / goalAmount;
                    progress = progress.clamp(0.0, 1.0);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              color: Colors.green,
                            ),
                            SizedBox(height: 4),
                            Text("£$totalDonations raised of £$goalAmount"),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CampaignDetailsPage(
                                userId: widget.userId,
                                campaignId: campaign.id,
                                
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
      appBar: AppBar(
        title: Text("My Campaigns"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Add New Campaign",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCampaignPage(userId: userId),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var campaigns = snapshot.data!.docs;

          if (campaigns.isEmpty) {
            return Center(child: Text("You have not created any campaigns."));
          }

          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              var campaign = campaigns[index];
              final totalDonations = campaign['totalDonations'] ?? 0;
              final goalAmount = campaign['goalAmount'] ?? 10000;

              double progress = totalDonations / goalAmount;
              progress = progress.clamp(0.0, 1.0);

              return Card(
                margin: EdgeInsets.all(16),
                child: ListTile(
                  title: Text(campaign['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campaign['description']),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                      SizedBox(height: 4),
                      Text("£$totalDonations raised of £$goalAmount"),
                    ],
                  ),
                  trailing: Text("£$totalDonations"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserCampaignDetailsPage(
                          campaignId: campaign.id,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}