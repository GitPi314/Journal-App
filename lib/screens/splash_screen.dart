// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  final StorageService _storageService = StorageService();
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadSplashSetting();
  }

  void _loadSplashSetting() async {
    try {
      bool? setting = await _storageService.getSplashScreenSetting();
      setState(() {
        _showSplash = setting; // Sicherstellen, dass _showSplash niemals null ist
      });

      if (_showSplash) {
        _authenticate();
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Fehler beim Laden der Splash-Einstellungen: $e');
      setState(() {
        _showSplash = false; // Fallback: Überspringe den SplashScreen bei Fehlern
      });
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // Authentifizierungslogik
  Future<void> _authenticate() async {
    try {
      bool canAuthenticate = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) {
        print('Biometrische Authentifizierung ist nicht verfügbar.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometrische Authentifizierung ist nicht verfügbar.')),
        );
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      _isAuthenticated = await auth.authenticate(
        localizedReason: 'Bitte authentifizieren Sie sich, um fortzufahren',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (_isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Optional: Zeige eine Fehlermeldung oder bleibe auf dem Splashscreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentifizierung fehlgeschlagen.')),
        );
      }
    } catch (e) {
      print('Fehler bei der Authentifizierung: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler bei der Authentifizierung.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hintergrundbild
          Image.asset(
            'lib/assets/images/splash_screen.png',
            fit: BoxFit.cover,
          ),
          // Loading-Indikator während der Authentifizierung
          if (_showSplash && !_isAuthenticated)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
