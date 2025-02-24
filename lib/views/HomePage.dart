import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final Color lightperiwinkle = const Color(0xFFBBA5E3);  // Purple-ish color for main elements
final Color lightLavender = const Color(0xFFD8BDDB);    // Light purple for subtle backgrounds
final Color mediumPurple = const Color(0xFF7D66B8);     // Medium shade for accents
final Color vibrantPink = const Color(0xFFB40085);

class Homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightLavender.withOpacity(0.3),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/appBackGround.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        // Add a child widget to display something over the background
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // You can add more UI elements here
          ],
        ),
      ),
    );
  }
}