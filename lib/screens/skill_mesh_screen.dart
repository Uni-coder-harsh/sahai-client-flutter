import 'dart:math';
import 'package:flutter/material.dart';
import '../models/concept_node.dart';
import '../models/dag_edge.dart';
import '../services/api_service.dart';

class SkillMeshScreen extends StatefulWidget {
  final String userId;

  const SkillMeshScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _SkillMeshScreenState createState() => _SkillMeshScreenState();
}

class _SkillMeshScreenState extends State<SkillMeshScreen> {
  final ApiService _apiService = ApiService();
  List<ConceptNode> _nodes = [];
  List<DagEdge> _edges = [];
  bool _isLoading = true;
  String _error = '';
  ConceptNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _apiService.fetchCurriculum('CS', userId: widget.userId);
      setState(() {
        _nodes = data['nodes'] ?? [];
        _edges = data['edges'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _nodes = _generateFallbackNodes();
        _edges = _generateFallbackEdges();
        _isLoading = false;
      });
    }
  }

  List<ConceptNode> _generateFallbackNodes() {
    final List<Map<String, dynamic>> mockData = [
      {'id': 'CS_PY_SYNTAX', 'name': 'Syntax & Semantics', 'mastery': 0.88, 'alpha': 8.8, 'beta': 1.2},
      {'id': 'CS_PY_VARIABLES', 'name': 'Variables & Memory', 'mastery': 0.82, 'alpha': 4.1, 'beta': 0.9},
      {'id': 'CS_PY_CONDITIONALS', 'name': 'Conditionals', 'mastery': 0.76, 'alpha': 3.8, 'beta': 1.2},
      {'id': 'CS_PY_LOOPS', 'name': 'Loops & Iteration', 'mastery': 0.44, 'alpha': 2.2, 'beta': 2.8},
      {'id': 'CS_PY_FUNCTIONS', 'name': 'Functions & Scope', 'mastery': 0.60, 'alpha': 3.0, 'beta': 2.0},
      {'id': 'CS_PY_LISTS_DICTS', 'name': 'Lists & Dictionaries', 'mastery': 0.68, 'alpha': 3.4, 'beta': 1.6},
      {'id': 'CS_PY_OOPS', 'name': 'OOP Concepts', 'mastery': 0.52, 'alpha': 2.6, 'beta': 2.4},
      {'id': 'CS_PY_EXCEPTIONS', 'name': 'Exception Handling', 'mastery': 0.58, 'alpha': 2.9, 'beta': 2.1},
      {'id': 'CS_PY_FILE_IO', 'name': 'File I/O', 'mastery': 0.38, 'alpha': 1.9, 'beta': 3.1},
      {'id': 'CS_PY_LIBRARIES', 'name': 'Modules & Packages', 'mastery': 0.50, 'alpha': 2.0, 'beta': 2.0},
    ];

    return mockData.map((d) {
      return ConceptNode(
        nodeId: d['id'],
        conceptName: d['name'],
        difficultyBaseline: 0.5,
        alpha: d['alpha'],
        beta: d['beta'],
        expectedMastery: d['mastery'],
        lastPracticed: DateTime.now(),
      );
    }).toList();
  }

  List<DagEdge> _generateFallbackEdges() {
    return [
      DagEdge(sourceNode: 'CS_PY_SYNTAX', targetNode: 'CS_PY_VARIABLES', edgeType: 'PREREQUISITE', correlationWeight: 0.85),
      DagEdge(sourceNode: 'CS_PY_SYNTAX', targetNode: 'CS_PY_CONDITIONALS', edgeType: 'PREREQUISITE', correlationWeight: 0.70),
      DagEdge(sourceNode: 'CS_PY_VARIABLES', targetNode: 'CS_PY_CONDITIONALS', edgeType: 'PREREQUISITE', correlationWeight: 0.75),
      DagEdge(sourceNode: 'CS_PY_CONDITIONALS', targetNode: 'CS_PY_LOOPS', edgeType: 'PREREQUISITE', correlationWeight: 0.80),
      DagEdge(sourceNode: 'CS_PY_VARIABLES', targetNode: 'CS_PY_LISTS_DICTS', edgeType: 'PREREQUISITE', correlationWeight: 0.85),
      DagEdge(sourceNode: 'CS_PY_LOOPS', targetNode: 'CS_PY_LISTS_DICTS', edgeType: 'PREREQUISITE', correlationWeight: 0.78),
      DagEdge(sourceNode: 'CS_PY_FUNCTIONS', targetNode: 'CS_PY_OOPS', edgeType: 'PREREQUISITE', correlationWeight: 0.82),
      DagEdge(sourceNode: 'CS_PY_SYNTAX', targetNode: 'CS_PY_FUNCTIONS', edgeType: 'PREREQUISITE', correlationWeight: 0.80),
      DagEdge(sourceNode: 'CS_PY_OOPS', targetNode: 'CS_PY_EXCEPTIONS', edgeType: 'DIAGNOSTIC_INFERENCE', correlationWeight: 0.65),
      DagEdge(sourceNode: 'CS_PY_FILE_IO', targetNode: 'CS_PY_EXCEPTIONS', edgeType: 'DIAGNOSTIC_INFERENCE', correlationWeight: 0.70),
      DagEdge(sourceNode: 'CS_PY_FUNCTIONS', targetNode: 'CS_PY_FILE_IO', edgeType: 'PREREQUISITE', correlationWeight: 0.60),
      DagEdge(sourceNode: 'CS_PY_SYNTAX', targetNode: 'CS_PY_LIBRARIES', edgeType: 'PREREQUISITE', correlationWeight: 0.50),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Cognitive Skill Mesh', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.greenAccent),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Stack(
              children: [
                // Interactive Grid Painter
                GestureDetector(
                  onTapUp: (details) => _handleCanvasTap(details.localPosition),
                  child: InteractiveViewer(
                    maxScale: 2.0,
                    minScale: 0.5,
                    child: Container(
                      width: 800,
                      height: 1000,
                      color: const Color(0xFF0F172A),
                      child: CustomPaint(
                        painter: MeshPainter(
                          nodes: _nodes,
                          edges: _edges,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Info Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey[800]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Personalized Python Subtopics graph. Green represents strong mastery (>75%), amber represents intermediate (50-75%), and red indicates weak concepts needing improvement.',
                            style: TextStyle(color: Colors.blueGrey[300], fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Drawer Slide-out Panel
                if (_selectedNode != null) _buildDetailDrawer(),
              ],
            ),
    );
  }

  void _handleCanvasTap(Offset tapPos) {
    ConceptNode? tapped;
    final centers = _getNodePositions(800, 1000);

    centers.forEach((nodeId, center) {
      final distance = (tapPos - center).distance;
      if (distance < 32) {
        tapped = _nodes.firstWhere((n) => n.nodeId == nodeId, orElse: () => _nodes[0]);
      }
    });

    setState(() {
      _selectedNode = tapped;
    });
  }

  Widget _buildDetailDrawer() {
    final node = _selectedNode!;
    final color = node.expectedMastery >= 0.75
        ? Colors.greenAccent
        : node.expectedMastery >= 0.50
            ? Colors.amberAccent
            : Colors.redAccent;

    // Reason suggestion dynamically based on mastery
    String actionSuggestion = '';
    if (node.expectedMastery < 0.50) {
      actionSuggestion = 'Concept is weak. Practice recommended. Choose related MCQ sprint on Hub or review syntax in Sandbox.';
    } else if (node.expectedMastery < 0.75) {
      actionSuggestion = 'Intermediate understanding. Focus on border case errors to strengthen this node.';
    } else {
      actionSuggestion = 'Mastery is solid. Proceeding to more advanced curriculum segments recommended.';
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.nodeId,
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.conceptName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.blueGrey),
                  onPressed: () => setState(() => _selectedNode = null),
                ),
              ],
            ),
            const Divider(color: Colors.blueGrey, height: 24),
            Row(
              children: [
                _buildDrawerParam('EXPECTED MASTERY', '${(node.expectedMastery * 100).toStringAsFixed(1)}%', color),
                const SizedBox(width: 24),
                _buildDrawerParam('ALPHA (SUCCESS)', node.alpha.toStringAsFixed(2), Colors.greenAccent),
                const SizedBox(width: 24),
                _buildDrawerParam('BETA (ERRORS)', node.beta.toStringAsFixed(2), Colors.redAccent),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              actionSuggestion,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'forgetting_curve_decay_rate: 0.02/day • last_practiced: ${node.lastPracticed.toLocal().toString().substring(0, 16)}',
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerParam(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static Map<String, Offset> _getNodePositions(double width, double height) {
    return {
      // Row 1 (Basics)
      'CS_PY_SYNTAX': Offset(width * 0.25, height * 0.15),
      'CS_PY_VARIABLES': Offset(width * 0.75, height * 0.15),
      // Row 2 (Control & Logic)
      'CS_PY_CONDITIONALS': Offset(width * 0.25, height * 0.35),
      'CS_PY_LOOPS': Offset(width * 0.75, height * 0.35),
      // Row 3 (Functions & Data Structures)
      'CS_PY_FUNCTIONS': Offset(width * 0.20, height * 0.55),
      'CS_PY_LISTS_DICTS': Offset(width * 0.80, height * 0.55),
      // Row 4 (OOP & Advanced)
      'CS_PY_OOPS': Offset(width * 0.20, height * 0.75),
      'CS_PY_EXCEPTIONS': Offset(width * 0.80, height * 0.75),
      // Row 5 (External Interface)
      'CS_PY_FILE_IO': Offset(width * 0.30, height * 0.90),
      'CS_PY_LIBRARIES': Offset(width * 0.70, height * 0.90),
    };
  }
}

class MeshPainter extends CustomPainter {
  final List<ConceptNode> nodes;
  final List<DagEdge> edges;

  MeshPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final posMap = _SkillMeshScreenState._getNodePositions(size.width, size.height);
    final nodeMap = {for (var n in nodes) n.nodeId: n};

    // Paint configuration for edges
    final paintEdge = Paint()
      ..color = Colors.blueGrey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintDiagEdge = Paint()
      ..color = Colors.blueGrey[800]!.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw Prerequisite Edges (Source -> Target links) dynamically from API
    for (var edge in edges) {
      final srcOffset = posMap[edge.sourceNode];
      final tgtOffset = posMap[edge.targetNode];
      if (srcOffset != null && tgtOffset != null) {
        final isDiag = edge.edgeType == 'DIAGNOSTIC_INFERENCE' || edge.edgeType == 'PERSONALIZED_LINK';
        canvas.drawLine(
          srcOffset,
          tgtOffset,
          isDiag ? paintDiagEdge : paintEdge,
        );

        // Optional: draw correlation weights text in the middle of edges
        final midX = (srcOffset.dx + tgtOffset.dx) / 2;
        final midY = (srcOffset.dy + tgtOffset.dy) / 2;
        final textSpan = TextSpan(
          style: TextStyle(color: Colors.blueGrey[500], fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
          text: edge.correlationWeight.toStringAsFixed(2),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - textPainter.height / 2));
      }
    }

    // Draw Concept Node circles
    posMap.forEach((nodeId, center) {
      final node = nodeMap[nodeId];
      final mastery = node?.expectedMastery ?? 0.5;
      
      Color color = Colors.redAccent;
      if (mastery >= 0.75) {
        color = Colors.greenAccent;
      } else if (mastery >= 0.50) {
        color = Colors.amberAccent;
      }

      // Outer glow circle
      canvas.drawCircle(
        center,
        36,
        Paint()..color = color.withOpacity(0.10)..style = PaintingStyle.fill,
      );

      // Node border
      canvas.drawCircle(
        center,
        28,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0,
      );

      // Node inner fill
      canvas.drawCircle(
        center,
        27,
        Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill,
      );

      // Text label for initials (e.g. SYN, VAR, COND, OOP)
      final label = nodeId.replaceFirst('CS_PY_', '').substring(0, min(4, nodeId.length - 6));
      final textSpan = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        text: label,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
