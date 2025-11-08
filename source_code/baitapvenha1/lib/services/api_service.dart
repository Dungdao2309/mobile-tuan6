// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:baitapvenha1/ models/task.dart';

class ApiService {
  final http.Client client;
  ApiService({http.Client? client}) : client = client ?? http.Client();

  static const String baseUrl = 'https://amock.io/api/researchUTH';

  Future<List<Task>> fetchTasks() async {
    final resp = await client.get(Uri.parse('$baseUrl/tasks'));
    if (resp.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(resp.body);
      if ((json['data'] ?? []) is List) {
        return (json['data'] as List)
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load tasks: ${resp.statusCode}');
    }
  }

  Future<Task> fetchTaskDetail(int id) async {
    final resp = await client.get(Uri.parse('$baseUrl/task/$id'));
    if (resp.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(resp.body);
      final data = json['data'];
      return Task.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load task detail: ${resp.statusCode}');
    }
  }

  Future<bool> deleteTask(int id) async {
    final uri = Uri.parse('$baseUrl/task/$id');
    http.Response resp;
    try {
      resp = await client.delete(uri);
    } catch (e) {
      print('DELETE request failed (network/exception): $e');
      rethrow;
    }

    print('DELETE $uri -> status=${resp.statusCode} body=${resp.body}');
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        try {
          final Map<String, dynamic> j = jsonDecode(resp.body);
          if (j.containsKey('isSuccess')) {
            print('Parsed delete response isSuccess=${j['isSuccess']} message=${j['message'] ?? ''}');
            return j['isSuccess'] == true;
          } else {
            print('No isSuccess field in delete response JSON.');
          }
        } catch (e) {
          print('Failed to parse delete response body as JSON: $e');
        }
      }
      // nếu status 200/204 mà không parse được body, coi như success (tuỳ ứng dụng)
      return true;
    }

    // fallback: không success
    print('DELETE returned non-success status: ${resp.statusCode}');
    return false;
  }
}
