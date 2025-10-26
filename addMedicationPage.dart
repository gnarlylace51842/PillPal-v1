import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notificationService.dart';

class AddMedicationPage extends StatefulWidget {
  final String userId;

  const AddMedicationPage({super.key, required this.userId});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _prescriberController = TextEditingController();

  String _selectedForm = 'Tablet';
  String _scheduleType = 'Time-based';
  bool _sleepAware = false;
  bool _isLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;
  String _skipDates = '';
  String _pillsRemaining = '';

  final _intervalController = TextEditingController();
  final _timesController = TextEditingController();

  List<String> _selectedDays = [];

  List<TextEditingController> _titrationWeekControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final List<String> _medicationForms = [
    'Tablet',
    'Capsule',
    'Liquid',
    'Injection',
    'Topical',
    'Inhaler',
  ];

  final List<String> _scheduleTypes = [
    'Time-based',
    'Interval',
    'Titration',
    'PRN (As Needed)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _instructionsController.dispose();
    _prescriberController.dispose();
    _intervalController.dispose();
    _timesController.dispose();
    for (var controller in _titrationWeekControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTitrationWeek() {
    setState(() {
      _titrationWeekControllers.add(TextEditingController());
    });
  }

  void _removeTitrationWeek(int index) {
    setState(() {
      _titrationWeekControllers[index].dispose();
      _titrationWeekControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Basic Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Lisinopril',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _strengthController,
                      decoration: const InputDecoration(
                        labelText: 'Strength',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 10',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedForm,
                      decoration: const InputDecoration(
                        labelText: 'Form',
                        border: OutlineInputBorder(),
                      ),
                      items: _medicationForms.map((form) {
                        return DropdownMenuItem(value: form, child: Text(form));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedForm = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Pills/Tablets Remaining',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 30',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _pillsRemaining = value;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Take with food',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prescriberController,
                decoration: const InputDecoration(
                  labelText: 'Prescriber (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Dr. Smith',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _scheduleType,
                decoration: const InputDecoration(
                  labelText: 'Schedule Type',
                  border: OutlineInputBorder(),
                ),
                items: _scheduleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _scheduleType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_scheduleType == 'Time-based') _buildTimeBasedSchedule(),
              if (_scheduleType == 'Interval') _buildIntervalSchedule(),
              if (_scheduleType == 'Titration') _buildTitrationSchedule(),
              if (_scheduleType == 'PRN (As Needed)') _buildPRNSchedule(),
              const SizedBox(height: 24),
              const Text(
                'Advanced Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            hintText: _startDate == null
                                ? 'Select date'
                                : '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}',
                          ),
                          controller: TextEditingController(
                            text: _startDate == null
                                ? ''
                                : '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _endDate = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'End Date (Optional)',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            hintText: _endDate == null
                                ? 'Select date'
                                : '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}',
                          ),
                          controller: TextEditingController(
                            text: _endDate == null
                                ? ''
                                : '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Skip Dates (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Format: MM/DD/YYYY, MM/DD/YYYY',
                ),
                onChanged: (value) {
                  _skipDates = value;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.archive),
                    label: const Text('Archive'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedication,
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
                          'Save Medication',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        List<String> titrationWeeks = [];
        if (_scheduleType == 'Titration') {
          titrationWeeks = _titrationWeekControllers
              .map((controller) => controller.text)
              .toList();
        }

        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/add_medication'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId,
            'name': _nameController.text,
            'strength': _strengthController.text,
            'form': _selectedForm,
            'instructions': _instructionsController.text,
            'prescriber': _prescriberController.text,
            'schedule_type': _scheduleType,
            'schedule_details': {
              'sleep_aware': _sleepAware,
              'interval_hours': _intervalController.text.isNotEmpty
                  ? int.tryParse(_intervalController.text)
                  : null,
              'times': _timesController.text,
              'selected_days': _selectedDays,
              'titration_weeks': titrationWeeks,
            },
            'start_date': _startDate?.toIso8601String(),
            'end_date': _endDate?.toIso8601String(),
            'skip_dates': _skipDates,
            'pills_remaining': _pillsRemaining,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 201) {
          if (!mounted) return;

          if (_startDate != null) {
            final medicationData = jsonDecode(response.body);
            final medicationId = medicationData['medication_id'];

            if (_scheduleType == 'Interval' &&
                _intervalController.text.isNotEmpty) {
              final intervalHours = int.tryParse(_intervalController.text) ?? 8;

              await NotificationService().scheduleMedicationReminders(
                medicationId: medicationId,
                medicationName: _nameController.text,
                startDate: _startDate!,
                endDate: _endDate,
                intervalHours: intervalHours,
                scheduleType: 'Interval',
              );
            } else if (_scheduleType == 'Time-based' &&
                _timesController.text.isNotEmpty) {
              final times = _timesController.text
                  .split(',')
                  .map((t) => t.trim())
                  .toList();

              await NotificationService().scheduleMedicationReminders(
                medicationId: medicationId,
                medicationName: _nameController.text,
                startDate: _startDate!,
                endDate: _endDate,
                scheduleType: 'Time-based',
                specificTimes: times,
              );
            }
          }

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication saved successfully!')),
          );
          Navigator.pop(context);
        } else {
          final error = jsonDecode(response.body);
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['error'] ?? 'Failed to save medication'),
            ),
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

  Widget _buildTimeBasedSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time-based Schedule',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _timesController,
          decoration: const InputDecoration(
            labelText: 'Times (e.g., 8:00 AM, 8:00 PM)',
            border: OutlineInputBorder(),
            hintText: 'Add times',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showDayPicker,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Days of Week',
              border: OutlineInputBorder(),
              hintText: 'Select days',
            ),
            child: Text(
              _selectedDays.isEmpty
                  ? 'Tap to select days'
                  : _selectedDays.join(', '),
              style: TextStyle(
                color: _selectedDays.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDayPicker() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(_selectedDays);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Days'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: days.map((day) {
                    return CheckboxListTile(
                      title: Text(day),
                      value: tempSelected.contains(day),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            tempSelected.add(day);
                          } else {
                            tempSelected.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIntervalSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interval Schedule',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _intervalController,
          decoration: const InputDecoration(
            labelText: 'Interval (hours)',
            border: OutlineInputBorder(),
            hintText: 'e.g., 6',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Sleep-aware (skip night hours)'),
          value: _sleepAware,
          onChanged: (value) {
            setState(() {
              _sleepAware = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTitrationSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Titration Schedule',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(_titrationWeekControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titrationWeekControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Week ${index + 1} Dosage',
                      border: const OutlineInputBorder(),
                      hintText: 'e.g., ${index + 1} tablet(s)',
                    ),
                  ),
                ),
                if (_titrationWeekControllers.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeTitrationWeek(index),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addTitrationWeek,
          icon: const Icon(Icons.add),
          label: const Text('Add more weeks'),
        ),
      ],
    );
  }

  Widget _buildPRNSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRN (As Needed)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Maximum Frequency',
            border: OutlineInputBorder(),
            hintText: 'e.g., Every 4 hours, max 3 times/day',
          ),
        ),
      ],
    );
  }
}
