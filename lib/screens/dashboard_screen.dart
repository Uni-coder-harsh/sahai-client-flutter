import 'dart:math';
import 'package:flutter/material.dart';
import '../models/concept_node.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback onStartSandbox;

  const DashboardScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.onStartSandbox,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<ConceptNode> _nodes = [];
  List<Map<String, dynamic>> _practiceQuestions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final data = await _apiService.fetchCognitiveState(widget.userId);
      
      // Filter out Python subtopics (for CS domain, focus on CS_PY_*)
      final pythonNodes = data.where((node) => node.nodeId.startsWith('CS_PY_')).toList();
      
      List<Map<String, dynamic>> practiceQ = [];
      try {
        practiceQ = await _apiService.fetchPracticeQuestions(widget.userId);
      } catch (pqErr) {
        print('Error loading practice questions: $pqErr');
      }

      setState(() {
        _nodes = pythonNodes.isNotEmpty ? pythonNodes : data;
        _practiceQuestions = practiceQ;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Connect your backend services to view active cognitive states.';
        _isLoading = false;
      });
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final textController = TextEditingController(text: ApiService.customBaseUrl ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Backend Configuration',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Server URL:',
                style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                ApiService.baseUrl,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Override Base URL:',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., http://192.168.1.100:3000/api',
                  hintStyle: TextStyle(color: Colors.blueGrey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blueGrey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.greenAccent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave blank to auto-resolve (localhost for Web/Desktop, 10.0.2.2 for Android Emulator).',
                style: TextStyle(color: Colors.blueGrey[400], fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                textController.clear();
                setState(() {
                  ApiService.customBaseUrl = null;
                });
                Navigator.of(context).pop();
                _loadState();
              },
              child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: const Color(0xFF0F172A),
              ),
              onPressed: () {
                final url = textController.text.trim();
                setState(() {
                  ApiService.customBaseUrl = url.isNotEmpty ? url : null;
                });
                Navigator.of(context).pop();
                _loadState();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPracticeDialog(Map<String, dynamic> question) {
    String? selectedOptId;
    bool isSubmitting = false;
    final options = question['options'] as List<dynamic>? ?? [];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Practice Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question['question_text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ...options.map((opt) {
                      final isSel = (selectedOptId == opt['id']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.greenAccent.withOpacity(0.1) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? Colors.greenAccent : Colors.transparent),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: isSel ? Colors.greenAccent : const Color(0xFF1E293B),
                            child: Text(opt['option_letter'] ?? '', style: TextStyle(color: isSel ? const Color(0xFF0F172A) : Colors.white, fontSize: 10)),
                          ),
                          title: Text(opt['option_text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          onTap: () {
                            setDialogState(() {
                              selectedOptId = opt['id'];
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                  onPressed: (selectedOptId == null || isSubmitting) ? null : () async {
                    setDialogState(() {
                      isSubmitting = true;
                    });
                    try {
                      final res = await _apiService.submitAnswer(
                        userId: widget.userId,
                        questionId: question['id'],
                        optionId: selectedOptId!,
                        timeSpentSeconds: 30,
                      );
                      
                      Navigator.pop(context); // Close practice dialog
                      
                      // Show result dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          title: Text(res['success'] == true ? 'Correct!' : 'Incorrect', style: TextStyle(color: res['success'] == true ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                          content: Text(
                            res['success'] == true 
                                ? 'Awesome job! Your mastery distribution has been updated.'
                                : 'Incorrect answer. Concept feedback indicates minor misunderstanding of ${res['misconceptions_detected']?.join(', ') ?? 'the topic'}. We will adjust practice recommendations.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _loadState(); // Refresh dashboard states
                              },
                              child: const Text('Done', style: TextStyle(color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
                    }
                  },
                  child: isSubmitting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A))) 
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avgMastery = _nodes.isEmpty
        ? 0.50
        : _nodes.map((e) => e.expectedMastery).reduce((a, b) => a + b) / _nodes.length;

    // Filter weakest subtopics
    final weakestNodes = _nodes.where((n) => n.expectedMastery < 0.60).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Slate Black
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            : RefreshIndicator(
                color: Colors.greenAccent,
                onRefresh: _loadState,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cognitive Hub',
                                style: TextStyle(
                                  color: Colors.blueGrey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome back, ${widget.userName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.blueGrey),
                                tooltip: 'Configure Backend Server',
                                onPressed: () => _showSettingsDialog(context),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: Colors.green[800],
                                radius: 24,
                                child: Text(widget.userName.substring(0, min(2, widget.userName.length)).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'EXPECTED MASTERY',
                              '${(avgMastery * 100).toStringAsFixed(1)}%',
                              Colors.green,
                              Icons.psychology,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              'PYTHON SUBTOPICS',
                              '${_nodes.length} Nodes',
                              Colors.blueAccent,
                              Icons.account_tree,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Skill Graph Chart / Radar Canvas
                      const Text(
                        'Cognitive Distribution Map',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildRadarMesh(avgMastery),
                      const SizedBox(height: 32),

                      // Weakest subtopics alert banner if any
                      if (weakestNodes.isNotEmpty) ...[
                        const Text(
                          'Topics Needing Improvement',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: weakestNodes.map((n) {
                            return Chip(
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              side: const BorderSide(color: Colors.redAccent),
                              label: Text(
                                '${n.conceptName} (${(n.expectedMastery * 100).toStringAsFixed(0)}%)',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // AI Curated Daily Sprint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'AI-Curated Practice Sprint',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Recommended',
                            style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDailySprintList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate secondary
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarMesh(double avgMastery) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: RadarPainter(mastery: avgMastery),
          child: Center(
            child: _error.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                    ),
                  )
                : Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildDailySprintList() {
    if (_practiceQuestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent[400], size: 40),
            const SizedBox(height: 12),
            const Text(
              'No practice questions remaining!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'You have mastered the curriculum topics or no practice questions exist in the database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _practiceQuestions.map((q) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey[800]!, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Practice Question',
                          style: TextStyle(color: Colors.greenAccent[400], fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Diff: ${double.parse(q['difficulty_level'].toString()).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.blueGrey[500], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      q['question_text'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.greenAccent, size: 24),
                onPressed: () => _showPracticeDialog(q),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double mastery;

  RadarPainter({required this.mastery});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.35;
    
    final paintGrid = Paint()
      ..color = Colors.blueGrey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintRadial = Paint()
      ..color = Colors.blueGrey[800]!
      ..strokeWidth = 1.0;

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4.0), paintGrid);
    }

    // Draw radial axes
    const int numAxes = 6;
    final double angleStep = (2 * pi) / numAxes;
    for (int i = 0; i < numAxes; i++) {
      final angle = i * angleStep;
      final endpoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endpoint, paintRadial);
    }

    // Draw student mastery polygon
    final path = Path();
    final masteryPoints = <Offset>[];
    
    final r = Random(42);
    for (int i = 0; i < numAxes; i++) {
      final angle = i * angleStep;
      final currentMastery = min(1.0, max(0.2, mastery + r.nextDouble() * 0.2 - 0.1));
      masteryPoints.add(Offset(
        center.dx + radius * currentMastery * cos(angle),
        center.dy + radius * currentMastery * sin(angle),
      ));
    }

    path.moveTo(masteryPoints[0].dx, masteryPoints[0].dy);
    for (int i = 1; i < numAxes; i++) {
      path.lineTo(masteryPoints[i].dx, masteryPoints[i].dy);
    }
    path.close();

    final paintPoly = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    final paintBorder = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, paintPoly);
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
