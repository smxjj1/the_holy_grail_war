import 'package:flutter/material.dart';

class MoreFeaturesPage extends StatelessWidget {
  const MoreFeaturesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更多玩法'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1B1E),
      body: const Center(
        child: Text(
          '更多玩法页面',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
} 