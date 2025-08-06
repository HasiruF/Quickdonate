import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserCampaignDetailsPage extends StatefulWidget {
  final String campaignId;
  final String userId;

  const UserCampaignDetailsPage({required this.campaignId, required this.userId, Key? key}) : super(key: key);

  @override
  _UserCampaignDetailsPageState createState() => _UserCampaignDetailsPageState();
}

class _UserCampaignDetailsPageState extends State<UserCampaignDetailsPage> {
  final _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final apiKey = '19be88726f8c55e045fcf31d98ffdd70';
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final response = await http.post(url, body: {
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        print('Imgbb upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> _submitPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add some text or select an image')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
        setState(() {
          _isUploading = false;
        });
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .collection('posts')
          .add({
        'content': content,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'postColor': 'white',
        'authorId': widget.userId,
      });

      _postController.clear();
      setState(() {
        _pickedImage = null;
        _isUploading = false;
      });
    } catch (e) {
      print('Error adding post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding post')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _endCampaign() async {
    try {
      // Mark campaign ended
      await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).update({
        'ended': true,
      });

      // Add "campaign ended" post in green
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .collection('posts')
          .add({
        'content': 'Campaign ended',
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': '',
        'authorId': widget.userId,
        'postColor': 'green',  // you can handle this on UI for color
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign ended successfully')));
    } catch (e) {
      print('Error ending campaign: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to end campaign')));
    }
  }

  Future<void> _deleteCampaign() async {
    try {
      await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign deleted')));
      Navigator.of(context).pop(); // Go back after deletion
    } catch (e) {
      print('Error deleting campaign: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete campaign')));
    }
  }

  Future<void> _changeGoal() async {
    final TextEditingController goalController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Goal Amount'),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter new goal amount (£)"),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            child: Text('Update'),
            onPressed: () {
              final val = int.tryParse(goalController.text);
              if (val != null && val > 0) {
                Navigator.of(context).pop(val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a valid positive number')));
              }
            },
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).update({
          'goalAmount': result,
        });

        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(widget.campaignId)
            .collection('posts')
            .add({
          'content': 'Goal changed to £$result',
          'timestamp': FieldValue.serverTimestamp(),
          'imageUrl': '',
          'authorId': widget.userId,
          'postColor': 'yellow', 
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal updated successfully')));
      } catch (e) {
        print('Error updating goal: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update goal')));
      }
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Widget _buildPostTile(DocumentSnapshot post) {
    String content = post['content'] ?? '';
    String imageUrl = post['imageUrl'] ?? '';
    Timestamp? timestamp = post['timestamp'] as Timestamp?;
    String timeText = timestamp != null ? timestamp.toDate().toString() : '';
    String? postColor = post['postColor'];

    Color? bgColor;
    if (postColor == 'green') {
      bgColor = Colors.green[100];
    } else if (postColor == 'yellow') {
      bgColor = Colors.yellow[100];
    }

    return Card(
      color: bgColor,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campaign Updates'),
      ),
      body: Column(
        children: [
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
                  itemBuilder: (context, index) => _buildPostTile(posts[index]),
                );
              },
            ),
          ),
          if (_isUploading) LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: InputDecoration(hintText: 'Write an update...'),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isUploading ? null : _submitPost,
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _deleteCampaign,
                    child: Text('Delete Campaign'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _changeGoal,
                    child: Text('Change Goal'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _endCampaign,
                    child: Text('End Campaign'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
