import 'package:flutter/material.dart';

import '../../../core/api_service.dart';

class ScanController {
  final ApiService apiService = ApiService();

  Future<Map<String, dynamic>> processQRCode(
      String data, Map<String, bool> selectedActions) async {
    try {
      debugPrint("Processing QR code data: $data");
      debugPrint("Selected actions: $selectedActions");

      if (data.isEmpty) {
        debugPrint("Empty QR code data");
        return {
          'status': 'error',
          'message': 'Empty QR code data',
        };
      }

      // Extract ticket code from the formatted data
      String ticketCode = "";

      // Split the data into lines
      List<String> lines = data.split('\n');

      // Process each line
      for (String line in lines) {
        line = line.trim();

        // Check for ticket code line (begins with "Code : ")
        if (line.toLowerCase().startsWith("code :") ||
            line.toLowerCase().startsWith("code:")) {
          ticketCode = line.split(':')[1].trim();
          debugPrint("Extracted ticket code: '$ticketCode'");
        }
      }

      // If we couldn't extract the data properly, provide error message
      if (ticketCode.isEmpty) {
        debugPrint("Failed to extract ticket code from data");
        return {
          'status': 'error',
          'message': 'Failed to extract ticket code from data',
        };
      }

      // Convert selected actions to the required format
      Map<String, String> distributionActions = {
        'distribution_jeton': selectedActions['jeton'] ?? false ? 'Oui' : 'Non',
        'nfi': selectedActions['nfi'] ?? false ? 'Oui' : 'Non',
        'outils': selectedActions['outils'] ?? false ? 'Oui' : 'Non',
        'semence': selectedActions['semence'] ?? false ? 'Oui' : 'Non',
      };

      // Send data to API
      return await apiService.sendScanData(ticketCode, distributionActions);
    } catch (e) {
      debugPrint("Error processing QR code: $e");
      return {
        'status': 'error',
        'message': 'Error processing QR code: $e',
      };
    }
  }
}
