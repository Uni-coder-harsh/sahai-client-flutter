import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class InitialTestScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const InitialTestScreen({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  State<InitialTestScreen> createState() => _InitialTestScreenState();
}

class _InitialTestScreenState extends State<InitialTestScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  // Timer fields
  late Stopwatch _stopwatch;
  late Timer _timer;
  int _elapsedSeconds = 0;

  String? _selectedOptionId;
  bool _isSubmittingAnswer = false;

  bool _isTestComplete = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final list = await _apiService.fetchInitialQuestions();
      setState(() {
        _questions = list;
        _isLoading = false;
      });
      if (list.isNotEmpty) {
        _startQuestionTimer();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial diagnostic test: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startQuestionTimer() {
    _elapsedSeconds = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  Future<void> _submitCurrentAnswer() async {
    if (_selectedOptionId == null) return;

    _stopwatch.stop();
    _timer.cancel();

    setState(() {
      _isSubmittingAnswer = true;
    });

    final currentQuestion = _questions[_currentIndex];
    
    try {
      // Submit answer to backend (triggers Bayesian updates & telemetry)
      await _apiService.submitAnswer(
        userId: widget.userId,
        questionId: currentQuestion['id'],
        optionId: _selectedOptionId!,
        timeSpentSeconds: _elapsedSeconds,
      );

      // Brief delay for transition
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentIndex + 1 < _questions.length) {
        // Go to next question
        setState(() {
          _currentIndex++;
          _selectedOptionId = null;
          _isSubmittingAnswer = false;
        });
        _startQuestionTimer();
      } else {
        // Diagnostic test complete
        setState(() {
          _isTestComplete = true;
          _isSubmittingAnswer = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit answer: ${e.toString()}')),
      );
      setState(() {
        _isSubmittingAnswer = false;
      });
      // Restart timer so they can try again
      _stopwatch.start();
      _startQuestionTimer();
    }
  }

  void _finishTest() {
    // Navigate to dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainAppShell(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _loadQuestions();
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (_isTestComplete) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.greenAccent,
                      size: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Diagnostic Test Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'We have processed your responses. Your profile has been updated, and your personal multidimensional cognitive vector is initialized on the cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey[300], fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _finishTest,
                    child: const Text(
                      'Go to Command Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final options = currentQuestion['options'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Initial Diagnostic Test', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
              const SizedBox(height: 24),

              // Timer & Difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.blueGrey, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Time spent: $_elapsedSeconds seconds',
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Diff: ${double.parse(currentQuestion['difficulty_level'].toString()).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Question Text Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey[800]!),
                ),
                child: Text(
                  currentQuestion['question_text'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),

              // Options list
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final isSelected = _selectedOptionId == opt['id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.greenAccent.withOpacity(0.08) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.greenAccent : Colors.blueGrey[800]!,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.greenAccent : const Color(0xFF0F172A),
                          foregroundColor: isSelected ? const Color(0xFF0F172A) : Colors.blueGrey[400],
                          radius: 16,
                          child: Text(opt['option_letter'] ?? ''),
                        ),
                        title: Text(
                          opt['option_text'] ?? '',
                          style: TextStyle(
                            color: isSelected ? Colors.greenAccent : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          if (!_isSubmittingAnswer) {
                            setState(() {
                              _selectedOptionId = opt['id'];
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Submit Answer Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_selectedOptionId == null || _isSubmittingAnswer)
                      ? null
                      : _submitCurrentAnswer,
                  child: _isSubmittingAnswer
                      ? const CircularProgressIndicator(color: Color(0xFF0F172A))
                      : const Text(
                          'Submit Answer',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
