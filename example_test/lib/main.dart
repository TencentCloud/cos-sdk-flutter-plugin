import 'package:flutter/material.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COS TEST',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Text('Test'),
    );
  }
}


