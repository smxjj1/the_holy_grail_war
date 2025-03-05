import 'package:flutter/material.dart';

class BasicControlPage extends StatelessWidget {
  const BasicControlPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基础控制'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1B1E),
      body: const Center(
        child: Text(
          '基础控制页面',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
} 