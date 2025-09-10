import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

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

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (doc.exists) {
        setState(() {
          _firstName = doc['username'] ?? '';
          _lastName = doc['lastname'] ?? '';
          _email = doc['email'] ?? '';
          _phone = doc['phone'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _startPayment(int amount) async {
    var paymentObject = {
      "sandbox": true, // PayHere sandbox mode
      "merchant_id": "1231961", 
      "merchant_secret": "MzE5OTQ5MDQ3MzEwOTIxNzEwNjcxODg2NjcyMDY3OTE0ODgxNzg1", 
      "notify_url": "http://sample.com/notify",
      "order_id": DateTime.now().millisecondsSinceEpoch.toString(),
      "items": widget.campaignTitle,
      "amount": amount.toString(),
      "currency": "LKR",
      "first_name": _firstName ?? "Donor",
      "last_name": _lastName ?? "Anonymous",
      "email": _email ?? "donor@example.com",
      "phone": _phone ?? "0000000000",
      "address": "Colombo",
      "city": "Colombo",
      "country": "Sri Lanka",
    };

    PayHere.startPayment(paymentObject, (paymentId) async {
      print("Payment Success. Payment Id: $paymentId");

      // Save donation after success
      await FirebaseFirestore.instance.collection('donations').add({
        'campaignId': widget.campaignId,
        'userId': widget.userId,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'paymentId': paymentId,
      });

      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .update({'totalDonations': widget.totalDonations + amount});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation successful!')),
      );

      Navigator.pop(context);
    }, (error) {
      print("Payment Failed. Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $error")),
      );
    }, () {
      print("Payment Dismissed");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment cancelled")),
      );
    });
  }

  Future<void> _submitDonation() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_firstName == null || _lastName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data not loaded yet')),
      );
      return;
    }

    _startPayment(amount);
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
            Text(widget.campaignTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(widget.campaignDescription),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: "Enter donation amount (LKR)"),
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
