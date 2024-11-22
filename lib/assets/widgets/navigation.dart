import 'package:flutter/material.dart';
import 'package:socialhub/components/home/home.dart';
import 'package:socialhub/components/message/message.dart';

class SocialMediaBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: Color(0xFF00364D),
            ),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/messages',
                (route) => false, // Remove all previous routes
              );
            },
          ),
          const SizedBox(width: 28),
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              color: Color(0xFF00364D),
            ),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false, // Remove all previous routes
              );
            },
          ),
          const SizedBox(width: 28),
          IconButton(
            icon: Icon(
              Icons.groups_2_outlined,
              color: Color(0xFF00364D),
            ),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/profile',
                (route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}
