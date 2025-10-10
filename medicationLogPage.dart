import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicationLogPage extends StatefulWidget {
  final String medicationId;
  final String userId;

  const MedicationLogPage({
    super.key,
    required this.medicationId,
    required this.userId,
  });

  @override
  State<MedicationLogPage> createState() => _MedicationLogPageState();
}

class _MedicationLogPageState extends State<MedicationLogPage> {
  Map<String, dynamic>? _medication;
  bool _isLoading = true;
  bool _isLogging = false;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  Future<void> _loadMedication() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:5000/get_medication/${widget.medicationId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _medication = data['medication'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logMedication() async {
    setState(() {
      _isLogging = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/log_medication'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'medication_id': widget.medicationId,
          'user_id': widget.userId,
        }),
      );

      setState(() {
        _isLogging = false;
      });

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication logged successfully!')),
        );

        await _loadMedication();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log medication')),
        );
      }
    } catch (e) {
      setState(() {
        _isLogging = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  int _getDaysRemaining() {
    if (_medication == null || _medication!['end_date'] == null) return 0;

    try {
      final endDate = DateTime.parse(_medication!['end_date']);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return 0;
    }
  }

  bool _needsRefill() {
    if (_medication == null) return false;

    final pillsRemaining =
        int.tryParse(_medication!['pills_remaining']?.toString() ?? '0') ?? 0;
    final daysRemaining = _getDaysRemaining();

    if (pillsRemaining < 10) {
      final intervalHours =
          _medication!['schedule_details']?['interval_hours'] ?? 24;
      final dosesPerDay = (24 / intervalHours).round();
      final pillsNeeded = dosesPerDay * daysRemaining;

      return pillsRemaining < pillsNeeded;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Log Medication'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medication == null
          ? const Center(child: Text('Medication not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_needsRefill())
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Low supply! Contact your doctor to refill.',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.medication,
                          size: 80,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _medication!['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_medication!['strength']} ${_medication!['form']}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: 'Instructions',
                    content:
                        _medication!['instructions'] ??
                        'No instructions provided',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.inventory,
                    title: 'Pills Remaining',
                    content:
                        '${_medication!['pills_remaining'] ?? 'Unknown'} left',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Days Until End',
                    content: '${_getDaysRemaining()} days',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLogging ? null : _logMedication,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLogging
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'I Took This Medication',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
