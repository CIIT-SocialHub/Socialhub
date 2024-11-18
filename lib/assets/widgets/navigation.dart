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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MessagePage()),
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
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          const SizedBox(width: 28),
          IconButton(
            icon: Icon(
              Icons.groups_2_outlined,
              color: Color(0xFF00364D),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
