// security_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final StorageService _storageService = StorageService();
  bool _enableSplashAuth = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  void _loadSecuritySettings() async {
    bool? setting = await _storageService.getSplashScreenSetting();
    setState(() {
      _enableSplashAuth = setting; // Default to true
    });
  }

  void _toggleSplashAuth(bool value) async {
    await _storageService.setSplashScreenSetting(value);
    setState(() {
      _enableSplashAuth = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sicherheit', style: TextStyle(color: Colors.white, fontSize: 24),),
      iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text(
                'Splashscreen mit Authentifizierung anzeigen',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              value: _enableSplashAuth,
              activeColor: Colors.greenAccent,
              onChanged: _toggleSplashAuth,
            ),
            // Weitere Sicherheitsoptionen können hier hinzugefügt werden
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
