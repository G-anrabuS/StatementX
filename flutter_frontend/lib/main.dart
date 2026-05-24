import 'package:flutter/material.dart';
import 'screens/upload_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const StatementXApp());
}

class StatementXApp extends StatelessWidget {
  const StatementXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StatementX',
      home: const HomeScreen(),
    );
  }
}
