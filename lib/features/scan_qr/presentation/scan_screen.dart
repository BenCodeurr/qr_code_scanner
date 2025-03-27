import 'package:flutter/material.dart';
import '../logic/scan_controller.dart';
import 'scanner_view.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanController _scanController = ScanController();
  bool jetonSelected = false;
  bool nfiSelected = false;
  bool outilsSelected = false;
  bool semenceSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UsM Qr Scanner"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/usm_scanner_logo.png'),
              const Text(
                'Scanner des codes QR pour vérifier et envoyer des données au serveur.',
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50.0),
              ElevatedButton.icon(
                onPressed: () => _openScanner(context),
                icon: const Icon(
                  Icons.qr_code_scanner,
                  size: 24,
                  color: Colors.white,
                ),
                label: const Text(
                  'Scannez',
                  style: TextStyle(fontSize: 18.0),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ScannerView(
          onScanComplete: (String data) {
            debugPrint("📱 ScanScreen received scanned data: $data");

            // Schedule this to run after the scanner screen is popped
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                debugPrint("📱 Showing dialog with data: $data");
                _showDataDialog(context, data);
              }
            });
          },
        ),
      ),
    )
        .then((_) {
      debugPrint("📱 Returned from scanner screen");
    });
  }

  void _showDataDialog(BuildContext context, String data) {
    // Extract the ticket code from the scanned data
    String ticketCode = '';
    final lines = data.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('code')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          ticketCode = parts[1].trim();
          break;
        }
      }
    }

    // Add additional info state variable
    String additionalInfo = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: () async {
                  // Show loading state
                  setState(() {
                    additionalInfo = 'Chargement...';
                  });

                  if (ticketCode.isEmpty) {
                    setState(() {
                      additionalInfo = 'Erreur: Code ticket non trouvé';
                    });
                    return;
                  }

                  // Fetch ticket info from server
                  final response = await _scanController.apiService
                      .checkTicketInfo(ticketCode);

                  if (!context.mounted) return;

                  if (response['exists'] == true) {
                    final info = response['info'] as String;
                    final infoType = response['info_type'] as String;

                    setState(() {
                      additionalInfo = '$infoType : $info';
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informations actualisées'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else {
                    setState(() {
                      additionalInfo = 'Erreur: ${response['error']}';
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Échec de l\'actualisation'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Actualiser les données',
              ),
              const Expanded(
                child: Text(
                  "RÉSULTAT DU SCAN",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattedDataText(data),
                      if (additionalInfo.isNotEmpty) ...[
                        const Divider(height: 24, thickness: 1),
                        _buildFormattedDataText(additionalInfo),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sélectionner l'action :",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 8),
                // Checkboxes for selecting items
                CheckboxListTile(
                  title: const Text("Distribution Jeton"),
                  value: jetonSelected,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (bool? value) {
                    setState(() {
                      jetonSelected = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text("NFI"),
                  value: nfiSelected,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (bool? value) {
                    setState(() {
                      nfiSelected = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text("Outils"),
                  value: outilsSelected,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (bool? value) {
                    setState(() {
                      outilsSelected = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text("Semence"),
                  value: semenceSelected,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (bool? value) {
                    setState(() {
                      semenceSelected = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Row(
                    children: [
                      Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text("Annuler", style: TextStyle(fontSize: 16))
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  onPressed: () {
                    // Include selected items in the data to send
                    String selectedItems = '';
                    if (jetonSelected) selectedItems += 'Jeton,';
                    if (nfiSelected) selectedItems += 'NFI,';
                    if (outilsSelected) selectedItems += 'Outils,';
                    if (semenceSelected) selectedItems += 'Semence,';

                    // Remove trailing comma if there are selections
                    if (selectedItems.isNotEmpty) {
                      selectedItems =
                          selectedItems.substring(0, selectedItems.length - 1);
                    }

                    // Add selections to data if any were made
                    String dataToSend = data;
                    if (selectedItems.isNotEmpty) {
                      dataToSend += '\nArticles: $selectedItems';
                    }

                    _handleSendData(dialogContext, dataToSend);
                  },
                  child: const Row(
                    children: [
                      Text(
                        "Envoyer",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_sharp,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actionsAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    );
  }

  Future<void> _handleSendData(BuildContext dialogContext, String data) async {
    // Check if at least one action is selected
    if (!jetonSelected && !nfiSelected && !outilsSelected && !semenceSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez sélectionner minimum une action.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Close the first dialog
    Navigator.of(dialogContext).pop();

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Envoie encours..."),
          ],
        ),
      ),
    );

    // Create a map of selected actions
    Map<String, bool> selectedActions = {
      'jeton': jetonSelected,
      'nfi': nfiSelected,
      'outils': outilsSelected,
      'semence': semenceSelected,
    };

    // Process data with selected actions
    final result = await _scanController.processQRCode(data, selectedActions);

    // Make sure the context is still valid
    if (!mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    // Show result dialog based on status
    if (result['status'] == 'success') {
      _showSuccessDialog(context, result['message']);
    } else {
      _showErrorDialog(context, result['message']);
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text(
              "Bien",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _openScanner(context);
            },
            child: const Text(
              "Autre Scan",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text(
              "Désolé",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _openScanner(context);
            },
            child: const Text(
              "Essayez encore",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedDataText(String data) {
    final lines = data.split('\n');
    final formattedLines = <Widget>[];

    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final label = parts[0].trim() + ':';
        final value = parts[1].trim();

        formattedLines.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      } else {
        // If line doesn't contain colon, just show as regular text
        formattedLines.add(
          Text(
            line,
            style: const TextStyle(
              fontFamily: 'poppins',
              fontSize: 20.0,
            ),
          ),
        );
      }

      // Add spacing between lines
      if (lines.indexOf(line) < lines.length - 1) {
        formattedLines.add(const SizedBox(height: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedLines,
    );
  }
}
