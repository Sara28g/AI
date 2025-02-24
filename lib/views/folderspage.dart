import 'package:flutter/material.dart';

final Color lightperiwinkle = const Color(0xFFBBA5E3);
final Color lightLavender = const Color(0xFFD8BDDB);
final Color mediumPurple = const Color(0xFF7D66B8);

class Folderspage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightLavender.withOpacity(0.3),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: mediumPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => Folderspage()),
            );
          },
          child: const Text(
            'Go to Another Page',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

