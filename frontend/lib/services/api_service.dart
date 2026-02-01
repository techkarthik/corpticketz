import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use localhost for Windows/Web. For Android Emulator use 10.0.2.2
  // Using 127.0.0.1 to avoid IPv6 resolution issues on Windows
  // For Android connectivity, use machine IP instead of 127.0.0.1
  // For local Windows development, 127.0.0.1 is most reliable.
  static const String baseUrl = 'http://141.148.218.210:3002/api'; 

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(String organizationId, String email, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'organization_id': organizationId, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));
      await prefs.setString('last_org_id', organizationId);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  Future<List<dynamic>> getTickets() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/tickets'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load tickets');
    }
  }
  
  Future<void> logout() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
  }

  // Master Data - Countries
  Future<List<dynamic>> getCountries() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/master/countries'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load countries');
    }
  }

  Future<void> createCountry(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/master/countries'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create country: ${response.body}');
    }
  }

  Future<void> updateCountry(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/master/countries/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update country: ${response.body}');
    }
  }

  Future<void> deleteCountry(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/master/countries/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete country: ${response.body}');
    }
  }

  Future<void> seedCountries() async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/master/countries/seed'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to seed countries: ${response.body}');
    }
  }

  Future<List<dynamic>> getBranches() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/master/branches'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load branches');
    }
  }

  Future<void> createBranch(Map<String, dynamic> data) async {
      final headers = await _getHeaders();
      final response = await http.post(
          Uri.parse('$baseUrl/master/branches'),
          headers: headers,
          body: jsonEncode(data),
      );
      if (response.statusCode != 201) {
           throw Exception('Failed to create branch: ${response.body}');
      }
  }

  Future<void> updateBranch(int id, Map<String, dynamic> data) async {
      final headers = await _getHeaders();
      final response = await http.put(
          Uri.parse('$baseUrl/master/branches/$id'),
          headers: headers,
          body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
           throw Exception('Failed to update branch: ${response.body}');
      }
  }

  Future<void> deleteBranch(int id) async {
      final headers = await _getHeaders();
      final response = await http.delete(
          Uri.parse('$baseUrl/master/branches/$id'),
          headers: headers,
      );
      if (response.statusCode != 200) {
           throw Exception('Failed to delete branch: ${response.body}');
      }
  }

  // Departments
  Future<List<dynamic>> getDepartments() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/master/departments'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load departments');
    }
  }

  Future<void> createDepartment(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/master/departments'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create department: ${response.body}');
    }
  }

  Future<void> updateDepartment(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/master/departments/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update department: ${response.body}');
    }
  }

  Future<void> deleteDepartment(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/master/departments/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete department: ${response.body}');
    }
  }

  Future<void> updateTicket(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/tickets/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update ticket: ${response.body}');
    }
  }

  Future<List<dynamic>> getTicketHistory(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/tickets/$id/history'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load ticket history');
    }
  }

  // Users
  Future<List<dynamic>> getUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/master/users'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/master/users'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/master/users/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> deleteUser(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/master/users/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  // Categories & Priorities
  Future<List<dynamic>> getCategories() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/master/categories'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/master/categories'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create category: ${response.body}');
    }
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/master/categories/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  Future<void> deleteCategory(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/master/categories/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  Future<List<dynamic>> getPriorities() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/master/priorities'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load priorities');
    }
  }

  Future<void> createPriority(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/master/priorities'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create priority: ${response.body}');
    }
  }

  Future<void> updatePriority(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/master/priorities/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update priority: ${response.body}');
    }
  }

  Future<void> deletePriority(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/master/priorities/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete priority: ${response.body}');
    }
  }

  Future<void> seedCategories() async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/master/categories/seed'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to seed categories: ${response.body}');
    }
  }

  Future<void> seedPriorities() async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/master/priorities/seed'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to seed priorities: ${response.body}');
    }
  }

  // Reports
  Future<Map<String, dynamic>> getReportSummary(Map<String, String> filters) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/reports/summary').replace(queryParameters: filters);
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load report summary: ${response.body}');
    }
  }
}
