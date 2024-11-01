// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:journal_app/screens/backup_screen.dart';
import 'package:journal_app/screens/security_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen', style: TextStyle(color: Colors.white, fontSize: 24),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Design-Einstellungen
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.white),
              title: const Text(
                'Design',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: () {
                // Navigiere zu den Design-Einstellungen
              },
            ),
            const Divider(color: Colors.grey),

            // Sicherheit-Einstellungen
            ListTile(
              leading: const Icon(Icons.security, color: Colors.white),
              title: const Text(
                'Sicherheit',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SecurityScreen(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.grey),

            // Backups-Einstellungen
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.white),
              title: const Text(
                'Backups',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BackupScreen(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.grey),

            // Weitere Einstellungen
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text(
                'Über',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: () {
                // Navigiere zu den Über-Informationen
              },
            ),
            const Divider(color: Colors.grey),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
