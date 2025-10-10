import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyInfoFormPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existingInfo;

  const EmergencyInfoFormPage({
    super.key,
    required this.userId,
    this.existingInfo,
  });

  @override
  State<EmergencyInfoFormPage> createState() => _EmergencyInfoFormPageState();
}

class _EmergencyInfoFormPageState extends State<EmergencyInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingInfo != null) {
      _doctorNameController.text = widget.existingInfo!['doctor_name'] ?? '';
      _contactInfoController.text = widget.existingInfo!['contact_info'] ?? '';
      _locationController.text = widget.existingInfo!['location'] ?? '';
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _contactInfoController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveEmergencyInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/save_emergency_info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId,
            'doctor_name': _doctorNameController.text,
            'contact_info': _contactInfoController.text,
            'location': _locationController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency info saved!')),
          );
          Navigator.pop(context);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save emergency info')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.existingInfo == null
              ? 'Add Emergency Info'
              : 'Edit Emergency Info',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency Contact Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your doctor or healthcare provider\'s information',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _doctorNameController,
                decoration: const InputDecoration(
                  labelText: 'Doctor/Supplier Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Dr. John Smith',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactInfoController,
                decoration: const InputDecoration(
                  labelText: 'Contact Information',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., (555) 123-4567',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact information';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location/Address',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 123 Main St, City, State',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEmergencyInfo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Emergency Information',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
