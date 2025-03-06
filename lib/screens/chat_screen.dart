import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paste Snap'),
      ),
      body: const Center(
        child: Text('Welcome to Paste Snap!'),
      ),
    );
  }
}
