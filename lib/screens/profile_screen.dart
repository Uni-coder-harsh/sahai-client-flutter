import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.fetchUserProfile(widget.userId);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.greenAccent),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadProfile();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _error.isNotEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(_error, style: TextStyle(color: Colors.blueGrey[400]), textAlign: TextAlign.center),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blueGrey[800]!),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.greenAccent,
                                  radius: 36,
                                  child: Text(
                                    (_userProfile?['name'] ?? 'S').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userProfile?['name'] ?? 'Student',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '@${_userProfile?['username'] ?? 'username'}',
                                        style: TextStyle(
                                          color: Colors.blueGrey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Profile Details Card
                          const Text(
                            'Academic Metadata',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blueGrey[800]!),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow('Academic Stream', _userProfile?['academic_stream'] ?? 'B.Tech CSE'),
                                const Divider(color: Color(0xFF0F172A), height: 20),
                                _buildDetailRow('Current Semester', 'Semester ${_userProfile?['current_semester'] ?? 1}'),
                                const Divider(color: Color(0xFF0F172A), height: 20),
                                _buildDetailRow('College Email', _userProfile?['sso_email'] ?? 'N/A'),
                                const Divider(color: Color(0xFF0F172A), height: 20),
                                _buildDetailRow('Phone Number', _userProfile?['phone_number'] ?? 'N/A'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Engine Personalization Info Card
                          const Text(
                            'Personalized Engine Details',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blueGrey[800]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Targeting GATE Exam?',
                                  (_userProfile?['device_signature']?['targeting_gate'] == true) ? 'YES' : 'NO',
                                  (_userProfile?['device_signature']?['targeting_gate'] == true) ? Colors.greenAccent : Colors.redAccent,
                                ),
                                if (_userProfile?['device_signature']?['targeting_gate'] == true) ...[
                                  const Divider(color: Color(0xFF0F172A), height: 20),
                                  _buildDetailRow('GATE Paper 1', _userProfile?['device_signature']?['gate_paper_1'] ?? 'N/A'),
                                  const Divider(color: Color(0xFF0F172A), height: 20),
                                  _buildDetailRow('GATE Paper 2', _userProfile?['device_signature']?['gate_paper_2'] ?? 'N/A'),
                                ],
                                const Divider(color: Color(0xFF0F172A), height: 20),
                                const Text(
                                  'Syllabus Reference / Topics:',
                                  style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _userProfile?['device_signature']?['syllabus_referral'] ?? 'No syllabus reference uploaded.',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String val, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          val,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
