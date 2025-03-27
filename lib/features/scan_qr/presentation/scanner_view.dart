import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerView extends StatefulWidget {
  final Function(String) onScanComplete;

  const ScannerView({
    Key? key,
    required this.onScanComplete,
  }) : super(key: key);

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool _scanComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  void _initializeScanner() {
    // Reset scan status
    _scanComplete = false;

    // Create and configure the controller
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Start scanning
    controller?.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    controller = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (controller == null) return;

    if (state == AppLifecycleState.resumed) {
      controller?.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller?.stop();
    }
  }

  // Process detected barcodes
  void _onDetect(BarcodeCapture capture) {
    // Prevent multiple detections
    if (_scanComplete) return;

    // Get barcodes from the capture
    final barcodes = capture.barcodes;

    // Log detection
    if (barcodes.isNotEmpty) {
      debugPrint("🔍 Scanner detected ${barcodes.length} barcodes");
    }

    // Process the first valid barcode
    for (final barcode in barcodes) {
      if (barcode.rawValue == null || barcode.rawValue!.isEmpty) continue;

      // Mark as complete to prevent further processing
      setState(() {
        _scanComplete = true;
      });

      // Extract barcode value
      final data = barcode.rawValue!;
      debugPrint("📱 Scanner captured barcode: $data");

      // Stop scanning
      controller?.stop();

      // Handle the scanned data safely
      _handleScannedData(data);

      // Only process the first valid barcode
      break;
    }
  }

  // Safely handle the scanned data
  void _handleScannedData(String data) {
    // Pass data to parent and navigate back
    // Using a slight delay to ensure UI state is consistent
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Pass data to parent
      widget.onScanComplete(data);

      // Pop back to previous screen
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scannez'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller?.toggleTorch(),
            tooltip: 'Activer/Désactiver le flash.',
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () => controller?.switchCamera(),
            tooltip: 'Inverser la caméra',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: controller!,
            onDetect: _onDetect,
            scanWindow: Rect.fromCenter(
              center: MediaQuery.of(context).size.center(Offset.zero),
              width: 250,
              height: 250,
            ),
          ),

          // Scan overlay with border
          Container(
            alignment: Alignment.center,
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
              child: Container(
                width: 250,
                height: 250,
              ),
            ),
          ),

          // Scanning indicator
          if (_scanComplete)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing QR code...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions text
          if (!_scanComplete)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Positionnez le code QR dans le cadre.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter to create a scan frame overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the scanner border
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw scanning corners
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    const cornerLength = 30.0;

    // Draw border
    canvas.drawRect(rect, borderPaint);

    // Top left corner
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(cornerLength, 0), cornerPaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(0, cornerLength), cornerPaint);

    // Top right corner
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(-cornerLength, 0), cornerPaint);
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(0, cornerLength), cornerPaint);

    // Bottom left corner
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(cornerLength, 0),
        cornerPaint);
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft.translate(0, -cornerLength), cornerPaint);

    // Bottom right corner
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(-cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(0, -cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
