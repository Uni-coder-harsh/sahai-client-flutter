import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'initial_test_screen.dart';

class PersonalizeScreen extends StatefulWidget {
  final String userId;

  const PersonalizeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String _selectedDomain = 'CS';
  final _courseController = TextEditingController(text: 'B.Tech');
  int _selectedSemester = 1;
  final _syllabusController = TextEditingController();
  
  bool _targetingGate = false;
  String _gatePaper1 = 'CS (Computer Science)';
  String _gatePaper2 = 'None';

  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _domains = ['CS (Computer Science)', 'Law', 'Arts', 'Management'];
  final List<String> _gatePapers = [
    'None',
    'CS (Computer Science)',
    'DA (Data Science & AI)',
    'EC (Electronics)',
    'EE (Electrical)',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check domain restriction
    if (_selectedDomain != 'CS') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Domain Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'we are still in progress with your domain we currently support cs , we have considered your request thank you .',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await _apiService.personalize(
        userId: widget.userId,
        domain: 'CS',
        course: _courseController.text.trim(),
        semester: _selectedSemester,
        syllabusTextOrLink: _syllabusController.text.trim(),
        gateExam: _targetingGate,
        gatePaper1: _gatePaper1,
        gatePaper2: _gatePaper2,
      );

      if (mounted) {
        if (res['status'] == 'success') {
          // Go to initial MCQ diagnostic test
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InitialTestScreen(
                userId: widget.userId,
                userName: res['user']['name'] ?? 'Student',
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Failed to personalize.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Personalize Your Engine', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Configure Your Learning Path',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us align the vector DB search and topic linkages specifically to your coursework and targets.',
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Domain Selector
                    const Text('Academic Domain', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey[800]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDomain == 'CS' ? _domains[0] : _selectedDomain,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          iconEnabledColor: Colors.greenAccent,
                          items: _domains.map((d) {
                            return DropdownMenuItem<String>(
                              value: d,
                              child: Text(d),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _selectedDomain = val.startsWith('CS') ? 'CS' : val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Course Input
                    _buildTextField(
                      controller: _courseController,
                      label: 'Degree Course (e.g. B.Tech, MCA, BSc)',
                      validator: (v) => v == null || v.isEmpty ? 'Course is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Semester Selector
                    const Text('Current Semester', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey[800]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedSemester,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          iconEnabledColor: Colors.greenAccent,
                          items: List.generate(8, (index) => index + 1).map((sem) {
                            return DropdownMenuItem<int>(
                              value: sem,
                              child: Text('Semester $sem'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _selectedSemester = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Syllabus Text or Link
                    _buildTextField(
                      controller: _syllabusController,
                      label: 'College Syllabus Reference (Paste Link/Topics)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // GATE Exam checkbox
                    SwitchListTile(
                      title: const Text(
                        'Targeting GATE Exam?',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        'Will prioritize core CS topics like OS, DBMS, Algorithms.',
                        style: TextStyle(color: Colors.blueGrey[400], fontSize: 11),
                      ),
                      activeColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.blueGrey[800],
                      value: _targetingGate,
                      onChanged: (val) {
                        setState(() {
                          _targetingGate = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_targetingGate) ...[
                      const Text('GATE Paper 1 Target', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey[800]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _gatePaper1,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            iconEnabledColor: Colors.greenAccent,
                            items: _gatePapers.where((e) => e != 'None').map((paper) {
                              return DropdownMenuItem<String>(
                                value: paper,
                                child: Text(paper),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _gatePaper1 = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('GATE Paper 2 Target', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey[800]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _gatePaper2,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            iconEnabledColor: Colors.greenAccent,
                            items: _gatePapers.map((paper) {
                              return DropdownMenuItem<String>(
                                value: paper,
                                child: Text(paper),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _gatePaper2 = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF0F172A))
                            : const Text('Save & Start Initial Diagnostic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
