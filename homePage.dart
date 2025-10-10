import 'package:flutter/material.dart';
import 'addMedicationPage.dart';
import 'currentMedicationsPage.dart';
import 'historyEmergencyPage.dart';
import 'calendarPage.dart';
import 'loginPage.dart';

class HomePage extends StatelessWidget {
  final String username;
  final String userId;

  const HomePage({super.key, required this.username, required this.userId});

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
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
            Text(username),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMenuCard(
              context,
              title: 'Add Medication',
              icon: Icons.add_circle_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicationPage(userId: userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Current Medications / Info.',
              icon: Icons.medication,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CurrentMedicationsPage(userId: userId),
                  ),
                );
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
                    builder: (context) => HistoryEmergencyPage(userId: userId),
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
                    builder: (context) => CalendarPage(userId: userId),
                  ),
                );
              },
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
