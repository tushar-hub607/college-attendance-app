import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'https://college-attendance-app-opnc.onrender.com';

  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body)['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> register(String name, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get all users list for admin popup (Naya Method Added)
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return [];
  }

  static Future<String?> startTeacherSession(String teacherId, String teacherName) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/start-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'teacherId': teacherId, 'teacherName': teacherName, 'date': today}),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body)['otp'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> markStudentAttendance(String studentId, String studentName, String otp) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.post(
        Uri.parse('$baseUrl/student/mark-attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': studentId, 'studentName': studentName, 'otp': otp, 'date': today}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getReports(String userId, String role) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/$userId/$role'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}