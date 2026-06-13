import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/concept_node.dart';
import '../models/dag_edge.dart';

class ApiService {
  static String? customBaseUrl;
  static String? token; // To store our AES-256 encrypted authentication token

  static dynamic _safeJsonDecode(String body, String defaultErrorMessage) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw Exception('$defaultErrorMessage (Raw: $body)');
    }
  }

  // Automatically resolve localhost for Web/Desktop and loopback IP for Android Emulator
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      final trimmed = envUrl.trim();
      if (!trimmed.endsWith('/api') && !trimmed.endsWith('/api/')) {
        return trimmed.endsWith('/') ? '${trimmed}api' : '$trimmed/api';
      }
      return trimmed;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    return Platform.isAndroid 
        ? 'http://10.0.2.2:3000/api' 
        : 'http://localhost:3000/api';
  }

  Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Signup a new user
  Future<Map<String, dynamic>> signup({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'phoneNumber': phoneNumber,
      }),
    );

    if (response.statusCode == 201) {
      final data = _safeJsonDecode(response.body, 'Failed to parse registration response.');
      token = data['token'];
      return data;
    } else {
      final errBody = _safeJsonDecode(response.body, 'Registration failed with status ${response.statusCode}.');
      throw Exception(errBody['error'] ?? 'Registration failed.');
    }
  }

  /// Login a user
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'Failed to parse login response.');
      token = data['token'];
      return data;
    } else {
      final errBody = _safeJsonDecode(response.body, 'Login failed with status ${response.statusCode}.');
      throw Exception(errBody['error'] ?? 'Login failed.');
    }
  }

  /// Personalize cognitive engine
  Future<Map<String, dynamic>> personalize({
    required String userId,
    required String domain,
    required String course,
    required int semester,
    required String syllabusTextOrLink,
    required bool gateExam,
    required String gatePaper1,
    required String gatePaper2,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/personalize'),
      headers: _headers,
      body: jsonEncode({
        'domain': domain,
        'course': course,
        'semester': semester,
        'syllabusTextOrLink': syllabusTextOrLink,
        'gateExam': gateExam,
        'gatePaper1': gatePaper1,
        'gatePaper2': gatePaper2,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error'] ?? 'Personalization failed.');
    }
  }

  /// Register student and initialize Gaussian belief priors (legacy endpoint kept for safety)
  Future<Map<String, dynamic>> onboardUser({
    required String email,
    required String academicStream,
    int semester = 1,
    int gradYear = 2027,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: jsonEncode({
        'sso_email': email,
        'academic_stream': academicStream,
        'current_semester': semester,
        'graduation_year': gradYear,
        'device_signature': {'client': 'FlutterApp', 'os': 'Linux'}
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Onboarding failed: ${response.body}');
    }
  }

  /// Retrieve current cognitive parameters (alpha, beta, mastery)
  Future<List<ConceptNode>> fetchCognitiveState(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/cognitive-state'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['cognitive_state'] ?? [];
      return list.map((item) => ConceptNode.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch cognitive state: ${response.body}');
    }
  }

  /// Retrieve student database profile
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  /// Load concepts and edges for graph visualization (personalized or baseline)
  Future<Map<String, dynamic>> fetchCurriculum(String domain, {String? userId}) async {
    final uri = userId != null
        ? Uri.parse('$baseUrl/curriculum/$domain?user_id=$userId')
        : Uri.parse('$baseUrl/curriculum/$domain');
        
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List rawNodes = data['nodes'] ?? [];
      final List rawEdges = data['edges'] ?? [];
      
      return {
        'nodes': rawNodes.map((n) => ConceptNode.fromJson(n)).toList(),
        'edges': rawEdges.map((e) => DagEdge.fromJson(e)).toList(),
      };
    } else {
      throw Exception('Failed to retrieve curriculum: ${response.body}');
    }
  }

  /// Fetch initial MCQ diagnostic questions
  Future<List<Map<String, dynamic>>> fetchInitialQuestions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/questions/initial'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch initial questions: ${response.body}');
    }
  }

  /// Submit an MCQ answer to trigger updates
  Future<Map<String, dynamic>> submitAnswer({
    required String userId,
    required String questionId,
    required String optionId,
    required int timeSpentSeconds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/questions/submit'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'question_id': questionId,
        'option_id': optionId,
        'time_spent_seconds': timeSpentSeconds,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit answer: ${response.body}');
    }
  }

  /// Fetch practice questions recommended for the user
  Future<List<Map<String, dynamic>>> fetchPracticeQuestions(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/questions/practice?user_id=$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch practice questions: ${response.body}');
    }
  }

  /// EnqueueTelemetry packet in Redis queue (asynchronous mathematical updating)
  Future<bool> sendTelemetry({
    required String userId,
    required String nodeId,
    required String eventType, // 'ATTEMPT', 'RUN', 'OCR'
    required bool success,
    required int attempts,
    required String codeSnippet,
    required List<String> behavioralFlags, // e.g. ['COPY_PASTE_PRONE']
    required int timeSpentSeconds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/telemetry'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'node_id': nodeId,
          'event_type': eventType,
          'success': success,
          'attempts': attempts,
          'code_snippet': codeSnippet,
          'behavioral_flags': behavioralFlags,
          'time_spent_seconds': timeSpentSeconds,
        }),
      );
      return response.statusCode == 202; // 202 Accepted
    } catch (e) {
      print('[ApiService] Connection error during telemetry transmission: $e');
      return false;
    }
  }
}
