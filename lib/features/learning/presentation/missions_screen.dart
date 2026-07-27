import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beginner Missions & XP')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: AppColors.profit),
              title: Text('Mission 1: First Virtual Trade'),
              subtitle:
                  Text('Execute a market buy order with ₹100,000 wallet.'),
              trailing: Text('+100 XP',
                  style: TextStyle(
                      color: AppColors.discipline,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: AppColors.primary),
              title: Text('Mission 2: Use a Stop-Loss Protection'),
              subtitle:
                  Text('Set a stop-loss order on any active crypto position.'),
              trailing: Text('+250 XP',
                  style: TextStyle(
                      color: AppColors.discipline,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
