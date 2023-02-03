import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {

  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面不存在'),
      ),
      body: const Center(
        child: Text('页面不存在'),
      ),
    );
  }
}
