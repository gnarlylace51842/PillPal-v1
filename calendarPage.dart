import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  final String userId;

  const CalendarPage({super.key, required this.userId});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  // ignore: unused_field
  String _viewMode = 'month';
  List<dynamic> _medications = [];
  final Map<String, Color> _medicationColors = {};
  bool _isLoading = true;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_medications/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _medications = data['medications'];
          _assignColors();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _assignColors() {
    for (int i = 0; i < _medications.length; i++) {
      _medicationColors[_medications[i]['_id']] =
          _availableColors[i % _availableColors.length];
    }
  }

  bool _isMedicationActiveOnDate(dynamic med, DateTime date) {
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

    return true;
  }

  int _getDosesPerDay(dynamic med) {
    if (med['schedule_type'] == 'Interval') {
      final intervalHours = med['schedule_details']?['interval_hours'];
      if (intervalHours != null) {
        return (24 / intervalHours).round();
      }
    }
    return 1;
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    List<DateTime> days = [];

    for (int i = 0; i < startWeekday; i++) {
      days.add(firstDay.subtract(Duration(days: startWeekday - i)));
    }

    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Calendar'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_module),
            onSelected: (value) => setState(() => _viewMode = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'month', child: Text('Month View')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildMonthView()),
                if (_medications.isNotEmpty) _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month - 1,
              );
            }),
          ),
          Expanded(
            child: Text(
              '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month + 1,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    final days = _getDaysInMonth(_selectedDate);
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == _selectedDate.month;
                final isToday =
                    day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;

                final activeMeds = _medications
                    .where((med) => _isMedicationActiveOnDate(med, day))
                    .toList();

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : isCurrentMonth
                        ? null
                        : Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isToday
                              ? Colors.white
                              : isCurrentMonth
                              ? Colors.black
                              : Colors.grey,
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                      if (isCurrentMonth && activeMeds.isNotEmpty)
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          alignment: WrapAlignment.center,
                          children: activeMeds.expand((med) {
                            final doses = _getDosesPerDay(med);
                            return List.generate(
                              doses,
                              (_) => Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _medicationColors[med['_id']],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medication Legend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _medications.map((med) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _medicationColors[med['_id']],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(med['name'] ?? 'Unknown'),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
