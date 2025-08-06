import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonatePage extends StatefulWidget {
  final String userId;
  final String campaignId;
  final String campaignTitle;
  final String campaignDescription;
  final int totalDonations;

  const DonatePage({
    required this.userId,
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignDescription,
    required this.totalDonations,
    super.key,
  });

  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitDonation() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add donation
      await FirebaseFirestore.instance.collection('donations').add({
        'campaignId': widget.campaignId,
        'userId': widget.userId,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update totalDonations in the campaign
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .update({'totalDonations': widget.totalDonations + amount});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation successful!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Donate to ${widget.campaignTitle}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.campaignTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(widget.campaignDescription),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter donation amount (£)"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDonation,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Donate Now"),
            ),
          ],
        ),
      ),
    );
  }
}