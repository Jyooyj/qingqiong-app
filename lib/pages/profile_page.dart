import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: const SafeArea(
        child: Center(child: Text('我的（占位）', style: TextStyle(fontSize: 18))),
      ),
    );
  }
}
