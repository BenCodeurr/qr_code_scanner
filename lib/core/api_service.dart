import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class ApiService {
  // final String _baseUrl = "http://172.20.10.3:8000";
  final String _baseUrl = "http://192.168.1.107:8000";

  // Set to false to use real API, true for mock testing
  final bool _useMockApi = false;

  Future<Map<String, dynamic>> sendScanData(
      String ticketCode, Map<String, String> distributionActions) async {
    // For debugging
    debugPrint(
        "API: Sending data - Ticket Code: '$ticketCode', Actions: $distributionActions");

    if (_useMockApi) {
      // Mock API implementation for testing
      return _mockSendScanData(ticketCode, distributionActions);
    }

    try {
      var url = Uri.parse('$_baseUrl/scan');
      debugPrint("API: Sending request to $url");

      final requestBody = json.encode({
        'ticket_code': ticketCode,
        ...distributionActions,
      });
      debugPrint("API: Request body: $requestBody");

      var response = await http.post(
        url,
        body: requestBody,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint("API: Success (${response.statusCode}) - ${response.body}");
        try {
          return json.decode(response.body);
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Failed to parse server response',
          };
        }
      } else {
        debugPrint("API: Error (${response.statusCode}) - ${response.body}");
        try {
          return json.decode(response.body);
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Failed to send data: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint("API: Exception - $e");
      return {
        'status': 'error',
        'message': 'Connection error: $e',
      };
    }
  }

  // New method to check ticket information
  Future<Map<String, dynamic>> checkTicketInfo(String ticketCode) async {
    debugPrint("API: Checking ticket info for: '$ticketCode'");

    if (_useMockApi) {
      // Mock implementation for testing
      return _mockCheckTicketInfo(ticketCode);
    }

    try {
      var url = Uri.parse('$_baseUrl/check-ticket');
      debugPrint("API: Sending request to $url");

      final requestBody = json.encode({'ticket_code': ticketCode});
      debugPrint("API: Request body: $requestBody");

      var response = await http.post(
        url,
        body: requestBody,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint("API: Success (${response.statusCode}) - ${response.body}");

        try {
          Map<String, dynamic> responseData = json.decode(response.body);
          return {
            'exists': responseData['exists'] ?? false,
            'info': responseData['info'] ?? '',
            'info_type': responseData['info_type'] ?? '',
          };
        } catch (parseError) {
          debugPrint("API: Error parsing response - $parseError");
          return {
            'success': false,
            'error': 'Failed to parse server response',
          };
        }
      } else {
        debugPrint("API: Error (${response.statusCode}) - ${response.body}");
        return {
          'success': false,
          'error': 'Server returned error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint("API: Exception - $e");
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  // Mock implementation for testing without a server
  Future<Map<String, dynamic>> _mockSendScanData(
      String ticketCode, Map<String, String> distributionActions) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate data (simple validation for demo)
    if (ticketCode.isEmpty) {
      debugPrint("Mock API: Ticket code cannot be empty");
      return {
        'status': 'error',
        'message': 'Ticket code cannot be empty',
      };
    }

    // Simulate some random failures (10% chance of failure)
    final random = math.Random();
    final success = random.nextDouble() > 0.1;

    if (success) {
      debugPrint("Mock API: Data sent successfully");
      debugPrint(
          "Mock API: Received ticket: '$ticketCode', actions: $distributionActions");
      return {
        'status': 'success',
        'message': 'Données mises à jour avec succès.',
      };
    } else {
      debugPrint("Mock API: Random failure simulated");
      return {
        'status': 'error',
        'message': 'Random failure simulated',
      };
    }
  }

  // Mock implementation for checking ticket info
  Future<Map<String, dynamic>> _mockCheckTicketInfo(String ticketCode) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Sample responses based on ticket code
    if (ticketCode.contains('USM') || ticketCode.contains('888')) {
      return {
        'success': true,
        'info': 'Activé',
        'info_type': 'Distribution',
      };
    } else if (ticketCode.contains('123')) {
      return {
        'success': true,
        'info': 'En attente',
        'info_type': 'Vérification',
      };
    } else {
      return {
        'success': true,
        'info': 'Non trouvé',
        'info_type': 'Inconnu',
      };
    }
  }
}
