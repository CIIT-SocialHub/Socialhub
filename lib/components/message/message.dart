import 'package:flutter/material.dart';
import 'package:socialhub/assets/widgets/navigation.dart';

class MessagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00364D),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMessageTile(
            context,
            avatarColor: const Color(0xFF4EC8F4),
            senderName: "John Doe",
            messagePreview: "Hey, are you ready for the quiz tomorrow?",
            timestamp: "10:30 AM",
          ),
          _buildMessageTile(
            context,
            avatarColor: const Color(0xFF00364D),
            senderName: "Anna Smith",
            messagePreview: "Can you send me the lecture notes?",
            timestamp: "9:15 AM",
          ),
          _buildMessageTile(
            context,
            avatarColor: const Color(0xFF4EC8F4),
            senderName: "Study Group",
            messagePreview: "Group project meeting at 4 PM. Don’t be late!",
            timestamp: "Yesterday",
          ),
          _buildMessageTile(
            context,
            avatarColor: const Color(0xFF00364D),
            senderName: "Dr. Williams",
            messagePreview: "Reminder: Submit your assignments by Friday.",
            timestamp: "2 days ago",
          ),
          _buildMessageTile(
            context,
            avatarColor: const Color(0xFF4EC8F4),
            senderName: "CIIT Events",
            messagePreview: "Join us for the upcoming Hackathon!",
            timestamp: "3 days ago",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOptions(context);
        },
        backgroundColor: const Color(0xFF4EC8F4),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SocialMediaBottomNavBar(),
    );
  }

  // Method to show the overlay with add options
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Add New',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00364D),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Add Message'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to the Add Message page or open a dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Add Group'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to the Add Group page or open a dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Add Community'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to the Add Community page or open a dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Message tile widget to display each message entry
  Widget _buildMessageTile(
    BuildContext context, {
    required Color avatarColor,
    required String senderName,
    required String messagePreview,
    required String timestamp,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            senderName[0], // Display the first letter of the sender’s name
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          senderName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00364D),
          ),
        ),
        subtitle: Text(
          messagePreview,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          timestamp,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        onTap: () {
          // Define action on tapping a message tile if needed
        },
      ),
    );
  }
}
