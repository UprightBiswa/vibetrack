import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.palette_rounded),
            title: Text('Theme'),
            subtitle: Text('Cyber-Bento Dark'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_active_rounded),
            title: Text('Notifications'),
            subtitle: Text('Deferred in MVP'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_rounded),
            title: Text('Privacy'),
            subtitle: Text('RLS + least privilege'),
          ),
        ],
      ),
    );
  }
}
