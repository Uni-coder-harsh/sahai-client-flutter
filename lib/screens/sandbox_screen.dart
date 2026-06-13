import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'failure_report_screen.dart';

class SandboxScreen extends StatefulWidget {
  final String userId;

  const SandboxScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _SandboxScreenState createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController(
    text: 'def solve_problem():\n    # Practice Python syntax here\n    # e.g., working with loops and lists\n    x = [i for i in range(10) if i % 2 == 0]\n    print(x)\n'
  );

  int _runCount = 0;
  bool _success = true;
  bool _didPaste = false;
  bool _isTransmitting = false;
  String _consoleOutput = 'Console initialized. Ready to execute code.';

  void _runCode() {
    setState(() {
      _runCount++;
      _consoleOutput = 'Compiling sandbox...\nExecuting tests for CS_PY_SYNTAX...\nTest 1/2: Syntax Check - PASSED\nTest 2/2: Logic Execution - PASSED\n\nOutput:\n[0, 2, 4, 6, 8]\n\nExecution completed successfully.';
    });
  }

  Future<void> _submitTelemetry(String nodeId) async {
    setState(() => _isTransmitting = true);

    final List<String> flags = [];
    if (_didPaste) flags.add('COPY_PASTE_PRONE');

    final ok = await _apiService.sendTelemetry(
      userId: widget.userId,
      nodeId: nodeId,
      eventType: 'CODE_SANDBOX',
      success: _success,
      attempts: _runCount == 0 ? 1 : _runCount,
      codeSnippet: _codeController.text,
      behavioralFlags: flags,
      timeSpentSeconds: 120,
    );

    if (ok) {
      // Allow Python math worker some buffer to process
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FailureReportScreen(
              userId: widget.userId,
              targetNodeId: nodeId,
              didPaste: _didPaste,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission rejected. Is your API Gateway running?')),
      );
    }
    setState(() => _isTransmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Practice Sandbox & OCR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: isMobile ? _buildMobileLayout() : _buildWebLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left Pane: Code Editor Area
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MODE A: CODE EDITING (DESKTOP WEB ONLY)',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.paste, size: 16),
                          label: const Text('Mock Paste'),
                          onPressed: () {
                            setState(() {
                              _codeController.text = 'def solve_problem():\n    # Pasted logic snippet\n    res = []\n    for i in range(10):\n        if i % 2 == 0:\n            res.append(i)\n    return res\n';
                              _didPaste = true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Run Code'),
                          onPressed: _runCode,
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                // Code input field
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey[800]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('CONSOLE OUTPUT', style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Mock compiler console
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _consoleOutput,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Vertical divider
        Container(width: 1, color: Colors.blueGrey[900]),

        // Right Pane: OCR Scan / Ingestion
        Expanded(
          flex: 4,
          child: _buildOcrPane('CS_PY_SYNTAX'),
        )
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Restricted Code Editor Notice
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.desktop_windows_outlined, color: Colors.amberAccent),
                    SizedBox(width: 10),
                    Text(
                      'Code Editor Web App Only',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Code editing is not optimized for mobile screens. Please launch this app in a browser to use the full-featured code editor. On mobile, use Handwriting OCR scanner below to scan handwritten derivations.',
                  style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, height: 1.4),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: _buildOcrPane('CS_PY_SYNTAX'),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrPane(String nodeId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HANDWRITING OCR NOTES INGESTION',
            style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 20),
          // Scanned notes area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey[800]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.blueGrey[600], size: 48),
                  const SizedBox(height: 12),
                  const Text('Capture Handwritten Notes', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Scan derivations or loops directly from your notebooks and convert them to cognitive parameters at \$0 cost.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusRow('Compilation Runs:', '$_runCount attempts'),
          _buildStatusRow('Copy-Paste Flagged:', _didPaste ? 'TRUE' : 'FALSE', _didPaste ? Colors.redAccent : Colors.blueGrey),
          const SizedBox(height: 24),
          // Submit buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isTransmitting ? null : () => _submitTelemetry(nodeId),
              child: _isTransmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit Sandbox Telemetry',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String val, [Color color = Colors.white]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 13)),
          Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
