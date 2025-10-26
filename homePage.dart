import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addMedicationPage.dart';
import 'currentMedicationsPage.dart';
import 'historyEmergencyPage.dart';
import 'calendarPage.dart';
import 'loginPage.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String userId;

  const HomePage({super.key, required this.username, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _todaysMedications = [];
  bool _isLoadingMeds = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysMedications();
  }

  Future<void> _loadTodaysMedications() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_medications/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final medications = data['medications'] as List;

        final today = DateTime.now();
        final todaysMeds = medications.where((med) {
          return _isMedicationForToday(med, today);
        }).toList();

        setState(() {
          _todaysMedications = todaysMeds;
          _isLoadingMeds = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMeds = false;
      });
    }
  }

  bool _isMedicationForToday(dynamic med, DateTime date) {
    final start = med['start_date'];
    final end = med['end_date'];

    if (start == null) return false;

    final startDate = DateTime.parse(start);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final checkDay = DateTime(date.year, date.month, date.day);

    if (checkDay.millisecondsSinceEpoch < startDay.millisecondsSinceEpoch) {
      return false;
    }

    if (end != null) {
      final endDate = DateTime.parse(end);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      if (checkDay.millisecondsSinceEpoch > endDay.millisecondsSinceEpoch) {
        return false;
      }
    }

    if (med['schedule_type'] == 'Time-based') {
      final selectedDays = med['schedule_details']?['selected_days'];

      if (selectedDays != null &&
          selectedDays is List &&
          selectedDays.isNotEmpty) {
        final weekdayNames = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        final dayName = weekdayNames[date.weekday - 1];
        return selectedDays.contains(dayName);
      }
    }

    return true;
  }

  int _getDosesPerDay(dynamic med) {
    if (med['schedule_type'] == 'Interval') {
      final intervalHours = med['schedule_details']?['interval_hours'];
      if (intervalHours != null) {
        return (24 / intervalHours).round();
      }
    } else if (med['schedule_type'] == 'Time-based') {
      final timesStr = med['schedule_details']?['times'];
      if (timesStr != null && timesStr.toString().isNotEmpty) {
        final times = timesStr.toString().split(',');
        return times.length;
      }
    }
    return 1;
  }

  Future<void> _markMedicationTaken(dynamic med) async {
    final medicationId = med['_id'];
    final dosesPerDay = _getDosesPerDay(med);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/mark_medication_taken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'medication_id': medicationId,
          'user_id': widget.userId,
          'doses_per_day': dosesPerDay,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _todaysMedications.removeWhere((m) => m['_id'] == medicationId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${med['name']} marked as taken!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Do you really want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(widget.username),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/pillpal_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PillPal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Medications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoadingMeds
                      ? const Center(child: CircularProgressIndicator())
                      : _todaysMedications.isEmpty
                      ? const Text(
                          'No more medications for today!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        )
                      : Column(
                          children: _todaysMedications.map((med) {
                            final dosesPerDay = _getDosesPerDay(med);
                            final pillsRemaining = med['pills_remaining'] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.medication,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '$pillsRemaining remaining; $dosesPerDay per day',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green[600],
                                      size: 32,
                                    ),
                                    onPressed: () => _markMedicationTaken(med),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMenuCard(
                    context,
                    title: 'Current Medications / Info.',
                    icon: Icons.medication,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CurrentMedicationsPage(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildMenuCard(
                    context,
                    title: 'Calendar',
                    icon: Icons.calendar_month,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CalendarPage(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildMenuCard(
                    context,
                    title: 'Add Medication',
                    icon: Icons.add_circle_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddMedicationPage(userId: widget.userId),
                        ),
                      ).then((_) => _loadTodaysMedications());
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildMenuCard(
                    context,
                    title: 'History / Emergency Info.',
                    icon: Icons.history,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HistoryEmergencyPage(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
