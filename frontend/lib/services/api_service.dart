import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/participant.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Q&A Related Methods

  /// Submits a new question
  static Future<Question> submitQuestion({
    required int sessionId,
    required int participantId,
    required String questionText,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${baseUrl}/qa/questions/submit/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'session': sessionId,
          'participant': participantId,
          'question_text': questionText,
          'is_anonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Question.fromJson(responseData);
      } else {
        throw Exception('Failed to submit question: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting question: $e');
    }
  }

  /// Gets all questions for a specific session
  static Future<List<Question>> getSessionQuestions(int sessionId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}/qa/sessions/$sessionId/questions/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Handle both formats: direct array or nested under 'questions' key
        final List<dynamic> questionsData =
            responseData is List
                ? responseData
                : (responseData['questions'] ?? []);

        return questionsData.map<Question>((json) {
          return Question.fromJson(json is Map<String, dynamic> ? json : {});
        }).toList();
      } else {
        throw Exception('Failed to load session questions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching session questions: $e');
    }
  }

  /// Mark a question as answered or unanswered via checkbox
  static Future<void> markQuestionAnswered(
    int questionId, {
    required bool isAnswered,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.patch(
        Uri.parse('${baseUrl}/qa/questions/$questionId/mark-answered/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_answered': isAnswered}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update question status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating question status: $e');
    }
  }

  /// Gets all questions asked by a specific participant
  static Future<List<Question>> getParticipantQuestions(
    int participantId,
  ) async {
    final response = await http.get(
      Uri.parse('${baseUrl}/qa/participants/$participantId/questions/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load participant questions');
    }
  }

  /// Gets all questions for a trainer's sessions
  static Future<List<Question>> getTrainerQuestions(
    int trainerId, {
    bool? answered,
    int? sessionId,
  }) async {
    final queryParams = <String, String>{};
    if (answered != null) queryParams['answered'] = answered.toString();
    if (sessionId != null) queryParams['session_id'] = sessionId.toString();

    final uri = Uri.parse(
      '${baseUrl}/qa/trainers/$trainerId/questions/',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trainer questions');
    }
  }

  /// Marks a question as answered
  static Future<void> markQuestionAsAnswered({
    required int questionId,
    required int trainerId,
    required String answerText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/qa/questions/$questionId/mark-answered/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'trainer_id': trainerId, 'answer_text': answerText}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark question as answered: ${response.body}');
    }
  }

  // Admin Comments Methods

  /// Submits a new admin comment for a session
  static Future<Map<String, dynamic>> submitAdminComment({
    required int sessionId,
    required String comment,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${baseUrl}/comments/sessions/$sessionId/submit/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'comment': comment}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit admin comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting admin comment: $e');
    }
  }

  /// Updates an existing admin comment for a session
  static Future<Map<String, dynamic>> updateAdminComment({
    required int sessionId,
    required String comment,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('${baseUrl}/comments/sessions/$sessionId/update/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'comment': comment}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update admin comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating admin comment: $e');
    }
  }

  /// Gets all admin comments for a session
  static Future<List<dynamic>> getSessionAdminComments(int sessionId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}/comments/sessions/$sessionId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData is List ? responseData : [responseData];
      } else {
        throw Exception('Failed to load admin comments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching admin comments: $e');
    }
  }

  /// Gets all admin comments for a workshop's sessions
  static Future<Map<int, List<dynamic>>> getWorkshopAdminComments(
    int workshopId,
  ) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}/comments/workshops/$workshopId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<int, List<dynamic>> commentsBySession = {};

        responseData.forEach((sessionId, comments) {
          final sessionIdInt = int.tryParse(sessionId);
          if (sessionIdInt != null) {
            commentsBySession[sessionIdInt] =
                comments is List ? comments : [comments];
          }
        });

        return commentsBySession;
      } else {
        throw Exception(
          'Failed to load workshop admin comments: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching workshop admin comments: $e');
    }
  }

  // Existing methods
  static Future<List<dynamic>> getSessions() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/sessions/'));
    if (response.statusCode == 200) {
      final sessions = jsonDecode(response.body);
      // Ensure token field is present in each session
      for (var session in sessions) {
        if (!session.containsKey('token') || session['token'] == null) {
          throw Exception('Session token is missing in the response.');
        }
      }
      return sessions;
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  static Future<Map<String, dynamic>> getSessionById(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/sessions/$sessionId/'),
    );
    if (response.statusCode == 200) {
      final sessions = jsonDecode(response.body);
      return sessions;
    } else {
      throw Exception('Failed to load session');
    }
  }

  static Future<bool> createSession(Map<String, dynamic> sessionData) async {
    try {
      // Create a new map to avoid modifying the original data
      final payload = Map<String, dynamic>.from(sessionData);

      // Ensure required fields are present
      if (!payload.containsKey('workshop_id') ||
          !payload.containsKey('date') ||
          !payload.containsKey('time')) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/workshops/sessions/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSessionsByIds(List ids) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workshops/sessions/batch/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ids': ids}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch sessions by IDs');
    }
  }

  static Future<List<dynamic>> getSessionsByWorkshopId(int workshopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/$workshopId/sessions/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sessions for workshop');
    }
  }

  static Future<List<String>> getEmailsBySession(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/sessions/$sessionId/emails/'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['emails']);
    } else {
      throw Exception('Failed to load emails');
    }
  }

  static Future<List<String>> getAllParticipantEmails() async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/participants/emails/'),
    );
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load participant emails');
    }
  }

  static Future<bool> updateSession(
    int sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      // Create a new map to avoid modifying the original data
      final payload = Map<String, dynamic>.from(sessionData);

      // Ensure required fields are present
      if (!payload.containsKey('workshop_id') ||
          !payload.containsKey('date') ||
          !payload.containsKey('time')) {
        print('Missing required fields in session data');
        return false;
      }

      print('Sending update session request with data: $payload');

      final response = await http.put(
        Uri.parse('$baseUrl/workshops/sessions/$sessionId/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print(
        'Update session response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update session: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating session: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getUpcomingSessions() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/sessions/'));
    if (response.statusCode == 200) {
      final sessions = jsonDecode(response.body) as List;
      final now = DateTime.now();
      // Filter sessions with date_time in the future
      final upcoming =
          sessions.where((s) {
            final dt = DateTime.tryParse(s['date'] ?? '');
            return dt != null && dt.isAfter(now);
          }).toList();
      // Sort by soonest first
      upcoming.sort(
        (a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
      );
      return upcoming;
    } else {
      throw Exception('Failed to load upcoming sessions');
    }
  }

  static Future<bool> deleteSession(int sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workshops/sessions/$sessionId/delete/'),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getParticipantTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/user_types/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participant types');
    }
  }

  static Future<bool> deleteParticipantType(int typeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user_types/$typeId/delete/'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createParticipantType(
    Map<String, dynamic> participantTypeData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_types/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(participantTypeData),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateParticipantType(
    int typeId,
    Map<String, dynamic> participantTypeData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user_types/$typeId/update/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(participantTypeData),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getRequiredFieldsForType(
    int typeId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user_types/$typeId/required-fields/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load required fields');
    }
  }

  static Future<Map<String, dynamic>> participantSignup(
    Participant participant,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accounts/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(participant.toJson(password: password)),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        // Return error details if available
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorData is Map ? errorData : {'detail': response.body},
          };
        } catch (e) {
          return {
            'success': false,
            'error': {
              'detail':
                  'Registration failed with status ${response.statusCode}',
            },
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': {'detail': 'Network error: $e'},
      };
    }
  }

  static Future<Map<String, dynamic>?> participantSignin(
    String nic,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/signin/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nic': nic, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/profile/$userId/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  static Future<void> updateUserProfile(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/accounts/profile/$userId/edit/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update profile');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String nic,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/change-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nic': nic,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      try {
        final body = jsonDecode(response.body);
        return {'success': false, 'error': body['error'] ?? 'Unknown error'};
      } catch (_) {
        return {'success': false, 'error': 'Unknown error'};
      }
    }
  }

  static Future<Map<String, dynamic>> registerUserForSession({
    required int userId,
    required int sessionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations/$userId/register-session/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'You have already registered for this session',
      };
    }
  }

  /// Cancels a user's registration for a session
  static Future<Map<String, dynamic>> cancelSessionRegistration({
    required int userId,
    required int sessionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations/cancel/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'participant': userId, 'session': sessionId}),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Successfully cancelled your registration',
      };
    } else if (response.statusCode == 404) {
      return {'success': false, 'message': 'No registration found to cancel'};
    } else {
      return {
        'success': false,
        'message': 'Failed to cancel registration. Please try again.',
      };
    }
  }

  static Future<int?> registerParticipant(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['id'];
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<List<dynamic>> getParticipants() async {
    final response = await http.get(Uri.parse('$baseUrl/users/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participants');
    }
  }

  static Future<bool> deleteParticipant(int participantId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$participantId/delete/'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> registerForSessionWithParticipant(
    int sessionId,
    int participantId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'participant_id': participantId,
        'session_id': sessionId,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<Map<String, int>> getAdminDashboardCounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/dashboard/admin/counts/'),
    );
    if (response.statusCode == 200) {
      return Map<String, int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load counts');
    }
  }

  static Future<List<dynamic>> getTrainers() async {
    final response = await http.get(Uri.parse('$baseUrl/trainers/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trainers');
    }
  }

  static Future<bool> deleteTrainer(int trainerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/trainers/$trainerId/delete/'),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getTrainerDetails(int trainerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trainers/$trainerId/details/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trainer details');
    }
  }

  static Future<Map<String, dynamic>> trainerLogin(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trainers/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  static Future<void> createTrainerCredential({
    required int trainerId,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trainers/$trainerId/credential/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw data['error'] ?? 'Failed to create credential';
    }
  }

  static Future<int?> createTrainerAndReturnId(
    Map<String, dynamic> trainerData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trainers/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trainerData),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] ?? data['trainer_id'];
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<void> updateTrainerCredential({
    required int trainerId,
    String? username,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (password != null) body['password'] = password;
    final response = await http.put(
      Uri.parse('$baseUrl/trainers/$trainerId/credential/update/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw data['error'] ?? 'Failed to update credential';
    }
  }

  static Future<bool> createTrainer(Map<String, dynamic> trainerData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trainers/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trainerData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<bool> updateTrainer(
    int trainerId,
    Map<String, dynamic> trainerData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/trainers/$trainerId/update/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trainerData),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<List<dynamic>> getWorkshops() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load workshops');
    }
  }

  static Future<bool> createWorkshop(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workshops/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<bool> deleteWorkshop(int workshopId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workshops/$workshopId/delete/'),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getWorkshopDetails(int workshopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/$workshopId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load workshop details');
    }
  }

  static Future<bool> updateWorkshop(
    int workshopId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workshops/$workshopId/update/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> assignTrainersToSession(
    int sessionId,
    List<int> trainerIds,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/assignments/trainers/sessions/assign/',
        ), // Corrected URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'trainer_ids': trainerIds}),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to assign trainers: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error assigning trainers: $e');
      return false;
    }
  }

  static Future<bool> removeTrainerFromSession(
    int sessionId,
    int trainerId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/assignments/trainers/sessions/remove/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'trainer_id': trainerId}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to remove trainer: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error removing trainer: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getParticipantByNIC(String nic) async {
    final response = await http.get(Uri.parse('$baseUrl/users/nic/$nic/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch participant details');
    }
  }

  static Future<bool> markAttendance(String token, String nic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations/sessions/$token/attendance/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nic': nic}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createFeedbackQuestion(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feedback/questions/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getFeedbackQuestions(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feedback/questions/$sessionId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load feedback questions');
    }
  }

  static Future<bool> submitFeedbackResponse(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feedback/responses/submit/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getFeedbackResponses(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feedback/responses/$sessionId/'),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Ensure the response is a List, otherwise return an empty list
      if (body is List) {
        return body;
      } else {
        return [];
      }
    } else {
      // Return empty list on error to avoid exceptions in UI
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSessionParticipantCounts(
    int sessionId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/registrations/sessions/$sessionId/participants/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participant counts');
    }
  }

  static Future<Map<String, dynamic>> getParticipantSessionsInfo(
    int participantId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$participantId/sessions/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participant sessions info');
    }
  }

  static Future<Map<String, dynamic>> getSessionDashboard(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/sessions/$sessionId/dashboard/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load session dashboard');
    }
  }

  static Future<Map<String, dynamic>> getParticipantById(
    int participantId,
  ) async {
    final response = await http.get(Uri.parse('$baseUrl/users/'));
    if (response.statusCode == 200) {
      final participants = jsonDecode(response.body) as List;
      return participants.firstWhere((p) => p['id'] == participantId);
    } else {
      throw Exception('Failed to load participant details');
    }
  }

  static Future<List<Map<String, dynamic>>> getParticipantsByIds(
    List ids,
  ) async {
    if (ids.isEmpty) {
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/batch/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': ids}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          'Failed to fetch participants by IDs: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch participants by IDs: $e');
    }
  }

  static Future<List<dynamic>> getSessionMaterials(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/materials/sessions/$sessionId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load session materials');
    }
  }

  static Future<Map<String, dynamic>> uploadSessionMaterial({
    required int sessionId,
    required int trainerId,
    String? url,
    String? description,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/materials/sessions/$sessionId/upload/'),
    );
    request.fields['uploaded_by'] = trainerId.toString();
    if (url != null && url.isNotEmpty) request.fields['url'] = url;
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      String errorMsg = 'Failed to upload material';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('error')) {
          errorMsg = body['error'].toString();
        } else if (body is Map && body.containsKey('non_field_errors')) {
          errorMsg = body['non_field_errors'].toString();
        } else if (body is Map && body.isNotEmpty) {
          errorMsg = body.values.first.toString();
        }
      } catch (_) {}
      return {'success': false, 'error': errorMsg};
    }
  }

  static Future<bool> deleteSessionMaterial(int materialId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/materials/sessions/materials/$materialId/delete/'),
    );
    return response.statusCode == 200;
  }

  /// Get sessions the participant has registered for (without materials field)
  static Future<List<dynamic>> getRegisteredSessions(int participantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/registrations/$participantId/registered-sessions/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load registered sessions');
    }
  }

  /// Get sessions the participant has attended
  static Future<List<dynamic>> getAttendedSessions(int participantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/registrations/$participantId/attended-sessions/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load attended sessions');
    }
  }

  /// Get sessions where the participant has submitted feedback (with responses)
  static Future<List<dynamic>> getFeedbackSubmittedSessions(
    int participantId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/registrations/$participantId/feedback-sessions/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load feedback submitted sessions');
    }
  }

  static Future<Map<String, dynamic>> getSessionsReportOverview({
    String period = 'custom',
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = <String, String>{'period': period};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    final uri = Uri.parse(
      '$baseUrl/analytics/reports/sessions-overview/',
    ).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sessions report overview');
    }
  }

  static Future<List<dynamic>> getNotifications(int participantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/participants/$participantId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<bool> markNotificationRead(int notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/mark-read/'),
    );
    return response.statusCode == 200;
  }

  static Future<String> getSessionToken(int sessionId) async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/sessions/'));
    if (response.statusCode == 200) {
      final sessions = jsonDecode(response.body) as List;
      final session = sessions.firstWhere(
        (s) => s['id'] == sessionId,
        orElse: () => throw Exception('Session not found'),
      );
      return session['token'] as String;
    } else {
      throw Exception('Failed to load session');
    }
  }

  /// Mark attendance for a session using QR code (session token and participant ID)
  static Future<Map<String, dynamic>> markAttendanceViaQR({
    required String sessionToken,
    required int participantId,
  }) async {
    final url = '$baseUrl/registrations/attendance/qr/';
    final requestBody = {
      'session_token': sessionToken,
      'participant_id': participantId,
    };

    print('Making API call to: $url');
    print('Request body: $requestBody');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('API Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      print('Error response: $data');
      return data;
    }
  }

  static Future<List<dynamic>> getSessionComments(int sessionId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/comments/sessions/$sessionId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load comments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading comments: $e');
    }
  }

  static Future<Map<String, dynamic>> submitComment({
    required int sessionId,
    required String comment,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/comments/sessions/$sessionId/submit/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'comment': comment, 'session': sessionId}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting comment: $e');
    }
  }
}
