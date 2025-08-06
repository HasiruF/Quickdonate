import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donate_screen.dart';

class CampaignDetailsPage extends StatefulWidget {
  final String campaignId;
  final String userId;

  const CampaignDetailsPage({
    required this.campaignId,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  _CampaignDetailsPageState createState() => _CampaignDetailsPageState();
}

class _CampaignDetailsPageState extends State<CampaignDetailsPage> {
  String campaignTitle = '';
  String campaignDescription = '';
  int totalDonations = 0;
  int goalAmount = 10000;
  bool ended = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCampaignData();
  }

  Future<void> _fetchCampaignData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .get();

      if (doc.exists) {
        setState(() {
          campaignTitle = doc['title'] ?? '';
          campaignDescription = doc['description'] ?? '';
          totalDonations = (doc['totalDonations'] ?? 0).toInt();
          goalAmount = (doc['goalAmount'] ?? 10000).toInt();
          ended = doc['ended'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          campaignTitle = 'Unknown Campaign';
          campaignDescription = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching campaign data: $e');
      setState(() {
        campaignTitle = 'Error loading campaign';
        campaignDescription = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double progress = 0.0;
    if (goalAmount > 0) {
      progress = (totalDonations / goalAmount).clamp(0.0, 1.0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(campaignTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campaignDescription, style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                ),
                SizedBox(height: 4),
                Text('£$totalDonations raised of £$goalAmount'),
                if (ended)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'This campaign has ended.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // ====== Posts ======
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('campaigns')
                  .doc(widget.campaignId)
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return Center(child: Text('No updates yet.'));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    String content = post['content'] ?? '';
                    String imageUrl = post['imageUrl'] ?? '';
                    String postColor = post['postColor'] ?? '';
                    Timestamp? timestamp = post['timestamp'] as Timestamp?;
                    String timeText = timestamp != null ? timestamp.toDate().toString() : '';

                    // Convert postColor to actual Color
                    Color? color;
                    switch (postColor) {
                      case 'green':
                        color = Colors.green[100];
                        break;
                      case 'yellow':
                        color = Colors.yellow[100];
                        break;
                      case 'red':
                        color = Colors.red[100];
                        break;
                      default:
                        color = null;
                    }

                    return Card(
                      color: color,
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(content),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.network(imageUrl, height: 150, fit: BoxFit.cover),
                              ),
                            SizedBox(height: 8),
                            Text(timeText, style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          
          Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('Donate'),
                onPressed: ended
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DonatePage(
                              userId: widget.userId,
                              campaignId: widget.campaignId,
                              campaignTitle: campaignTitle,
                              campaignDescription: campaignDescription,
                              totalDonations: totalDonations,
                            ),
                          ),
                        );
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}