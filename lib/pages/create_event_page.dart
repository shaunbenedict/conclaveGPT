import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _whatController = TextEditingController();
  final _whyController = TextEditingController();
  final _whoController = TextEditingController();
  final _whereController = TextEditingController();
  final _howMuchController = TextEditingController();
  final _registrationUrlController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _whatController.dispose();
    _whyController.dispose();
    _whoController.dispose();
    _whereController.dispose();
    _howMuchController.dispose();
    _registrationUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFAEB92),
              surface: Color(0xFF36656B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFAEB92),
                surface: Color(0xFF36656B),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance.collection('events').add({
        'name': _nameController.text,
        'what': _whatController.text,
        'why': _whyController.text,
        'who': _whoController.text,
        'when': Timestamp.fromDate(_selectedDateTime!),
        'where': _whereController.text,
        'howMuch': _howMuchController.text,
        'registrationUrl': _registrationUrlController.text,
        'organizerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Event',
          style: TextStyle(color: Color(0xFFFAEB92)),
        ),
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFAEB92)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Event Name',
                    icon: Icons.event,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter event name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _whatController,
                    label: 'What',
                    icon: Icons.description,
                    maxLines: 3,
                    hint: 'Describe the event',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe what the event is about';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _whyController,
                    label: 'Why',
                    icon: Icons.question_answer,
                    maxLines: 3,
                    hint: 'Purpose of the event',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please explain why this event is happening';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _whoController,
                    label: 'Who',
                    icon: Icons.people,
                    hint: 'Target audience',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please specify who can attend';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF36656B),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFFAEB92)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFFAEB92),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDateTime == null
                                  ? 'When - Select date and time'
                                  : 'When: ${_selectedDateTime!.toString().substring(0, 16)}',
                              style: TextStyle(
                                color: _selectedDateTime == null
                                    ? Colors.grey
                                    : Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _whereController,
                    label: 'Where',
                    icon: Icons.location_on,
                    hint: 'Event location',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please specify the location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _howMuchController,
                    label: 'How much',
                    icon: Icons.attach_money,
                    hint: 'Price or "Free"',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please specify the price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _registrationUrlController,
                    label: 'Registration URL',
                    icon: Icons.link,
                    hint: 'Link to register',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please provide a registration URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _registrationUrlController,
                    label: 'Registration URL',
                    icon: Icons.link,
                    hint: 'Link to register',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please provide a registration URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            color: Color(0xFFFAEB92),
                            radius: 16,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _createEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFAEB92),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Create Event',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFFAEB92)),
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFFAEB92)),
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFAEB92)),
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFAEB92), width: 2),
          borderRadius: BorderRadius.circular(25),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(25),
        ),
        filled: true,
        fillColor: const Color(0xFF36656B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
