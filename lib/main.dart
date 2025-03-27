import 'package:flutter/material.dart';

import 'features/scan_qr/presentation/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyScanner());
}

class MyScanner extends StatelessWidget {
  const MyScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "UsM Qr Scanner",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScanScreen(),
    );
  }
}
