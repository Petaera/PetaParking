import 'package:flutter/material.dart';
import 'webview_screen.dart'; // Make sure the filename is correct

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peta Parking',
      debugShowCheckedModeBanner: false,
      home: const WebViewScreen(
        url: 'https://parking.petaera.com', // Replace with your URL
      ),
    );
  }
}
