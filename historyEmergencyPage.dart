import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'emergencyInfoFormPage.dart';

class HistoryEmergencyPage extends StatefulWidget {
  final String userId;

  const HistoryEmergencyPage({super.key, required this.userId});

  @override
  State<HistoryEmergencyPage> createState() => _HistoryEmergencyPageState();
}

class _HistoryEmergencyPageState extends State<HistoryEmergencyPage> {
  List<dynamic> _medicationHistory = [];
  Map<String, dynamic>? _emergencyInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final historyResponse = await http.get(
        Uri.parse(
          'http://127.0.0.1:5000/get_medication_history/${widget.userId}',
        ),
      );

      final emergencyResponse = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_emergency_info/${widget.userId}'),
      );

      if (historyResponse.statusCode == 200) {
        final data = jsonDecode(historyResponse.body);
        setState(() {
          _medicationHistory = data['history'];
        });
      }

      if (emergencyResponse.statusCode == 200) {
        final data = jsonDecode(emergencyResponse.body);
        setState(() {
          _emergencyInfo = data['emergency_info'];
        });
      }

      setState(() {
        _isLoading = false;
      });
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

  Future<void> _deleteHistoryRecord(String recordId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_history_record/$recordId'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record deleted')));
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('History / Emergency Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _medicationHistory.isEmpty
                      ? const Text(
                          'No medication history recorded yet',
                          style: TextStyle(fontSize: 16),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _medicationHistory.length,
                          itemBuilder: (context, index) {
                            final record = _medicationHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  record['medication_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Pills taken: ${record['pills_taken'] ?? 0}\n'
                                  'Date: ${record['date'] ?? 'N/A'}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Record'),
                                        content: const Text(
                                          'Are you sure you want to delete this record?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteHistoryRecord(
                                                record['_id'],
                                              );
                                            },
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),
                  const Text(
                    'Emergency Information',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _emergencyInfo == null
                      ? Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmergencyInfoFormPage(
                                    userId: widget.userId,
                                  ),
                                ),
                              ).then((_) => _loadData());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Emergency Information'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Contact Details',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EmergencyInfoFormPage(
                                                  userId: widget.userId,
                                                  existingInfo: _emergencyInfo,
                                                ),
                                          ),
                                        ).then((_) => _loadData());
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Name: ${_emergencyInfo!['doctor_name'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Contact: ${_emergencyInfo!['contact_info'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Location: ${_emergencyInfo!['location'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
