import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCampaignPage extends StatefulWidget {
  final String userId;

  const AddCampaignPage({required this.userId, super.key});

  @override
  _AddCampaignPageState createState() => _AddCampaignPageState();
}

class _AddCampaignPageState extends State<AddCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitCampaign() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final goalAmount = double.parse(_goalController.text.trim());

        await FirebaseFirestore.instance.collection('campaigns').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'userId': widget.userId,
          'totalDonations': 0,
          'goalAmount': goalAmount,
          'ended' : false,
          'createdAt': FieldValue.serverTimestamp(),
          
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campaign added successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding campaign: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create New Campaign")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Campaign Title"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter a title" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter a description" : null,
              ),
              TextFormField(
                controller: _goalController,
                decoration: InputDecoration(labelText: "Goal Amount (£)"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a goal amount";
                  }
                  final n = num.tryParse(value);
                  if (n == null || n <= 0) {
                    return "Please enter a valid positive number";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCampaign,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Submit Campaign"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}