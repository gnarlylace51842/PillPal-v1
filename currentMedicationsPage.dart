import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notificationService.dart';

class CurrentMedicationsPage extends StatefulWidget {
  final String userId;

  const CurrentMedicationsPage({super.key, required this.userId});

  @override
  State<CurrentMedicationsPage> createState() => _CurrentMedicationsPageState();
}

class _CurrentMedicationsPageState extends State<CurrentMedicationsPage> {
  List<dynamic> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_medications/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _medications = data['medications'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load medications')),
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

  Future<void> _deleteMedication(String medicationId) async {
    try {
      await NotificationService().cancelMedicationReminders(medicationId);

      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_medication/$medicationId'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medication deleted')));
        _loadMedications();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete medication')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'No end date';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getNextDoseTime(dynamic medication) {
    final scheduleType = medication['schedule_type'];
    final now = DateTime.now();

    if (scheduleType == 'Interval') {
      final intervalHours = medication['schedule_details']?['interval_hours'];
      if (intervalHours != null) {
        final timesPerDay = (24 / intervalHours).round();
        final hoursPerDose = 24 / timesPerDay;

        for (int i = 0; i < timesPerDay; i++) {
          final hour = (i * hoursPerDose).round();
          final nextDose = DateTime(now.year, now.month, now.day, hour, 0);

          if (nextDose.isAfter(now)) {
            final timeStr = _formatTime(hour, 0);
            return 'Today at $timeStr';
          }
        }

        final firstHour = 0;
        final timeStr = _formatTime(firstHour, 0);
        return 'Tomorrow at $timeStr';
      }
    } else if (scheduleType == 'Time-based') {
      final timesStr = medication['schedule_details']?['times'];
      if (timesStr != null && timesStr != '') {
        final times = timesStr.toString().split(',');

        for (final timeStr in times) {
          final time = _parseTime(timeStr.trim());
          if (time != null) {
            final nextDose = DateTime(
              now.year,
              now.month,
              now.day,
              time.hour,
              time.minute,
            );

            if (nextDose.isAfter(now)) {
              return 'Today at ${_formatTime(time.hour, time.minute)}';
            }
          }
        }

        // If all doses today have passed, show tomorrow's first dose
        if (times.isNotEmpty) {
          final firstTime = _parseTime(times.first.trim());
          if (firstTime != null) {
            return 'Tomorrow at ${_formatTime(firstTime.hour, firstTime.minute)}';
          }
        }
      }
    }

    return 'No schedule set';
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final cleanStr = timeStr.toUpperCase().trim();
      final isPM = cleanStr.contains('PM');
      final isAM = cleanStr.contains('AM');

      final timeOnly = cleanStr
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();
      final parts = timeOnly.split(':');
      if (parts.length != 2) return null;

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  String _getPillsRemainingText(dynamic med) {
    final pillsRemaining = med['pills_remaining'];

    if (pillsRemaining == null || pillsRemaining.toString().isEmpty) {
      return 'N/A';
    }

    return pillsRemaining.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Current Medications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
          ? const Center(
              child: Text(
                'No medications added yet',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final med = _medications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                med['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Medication'),
                                    content: const Text(
                                      'Are you sure you want to delete this medication?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteMedication(med['_id']);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${med['strength'] ?? ''} ${med['form'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Next dose: ${_getNextDoseTime(med)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.medication, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pills remaining: ${_getPillsRemainingText(med)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Ends: ${_formatDate(med['end_date'])}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
