// backup_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/storage_service.dart';
import 'package:workmanager/workmanager.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final StorageService _storageService = StorageService();
  String _backupStatus = '';
  bool _isAutomaticBackupEnabled = false;
  String _selectedInterval = 'Täglich';

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    // Initialisiere Workmanager (nur einmal, falls noch nicht geschehen)
  }

  Future<void> _initializeSettings() async {
    bool isEnabled = await _storageService.isAutomaticBackupEnabled();
    String interval = await _storageService.getBackupInterval();
    setState(() {
      _isAutomaticBackupEnabled = isEnabled;
      _selectedInterval = interval;
    });
    if (_isAutomaticBackupEnabled) {
      _scheduleBackup(interval);
    }
  }

  // Methode zum Exportieren der Daten
  Future<void> _exportData() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String backupPath = '${appDocDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json';

      await _storageService.exportData(backupPath);

      setState(() {
        _backupStatus = 'Backup erfolgreich exportiert: $backupPath';
      });
    } catch (e) {
      setState(() {
        _backupStatus = 'Fehler beim Exportieren des Backups: $e';
      });
    }
  }

  // Methode zum Importieren der Daten
  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String importPath = result.files.single.path!;
        await _storageService.importData(importPath);

        setState(() {
          _backupStatus = 'Backup erfolgreich importiert von: $importPath';
        });
      } else {
        setState(() {
          _backupStatus = 'Import abgebrochen.';
        });
      }
    } catch (e) {
      setState(() {
        _backupStatus = 'Fehler beim Importieren des Backups: $e';
      });
    }
  }

  // Methode zum Festlegen des Backup-Intervalls
  Future<void> _setBackupInterval(String interval) async {
    await _storageService.setBackupInterval(interval);
    setState(() {
      _selectedInterval = interval;
      _backupStatus = 'Automatisches Backup auf $interval gesetzt.';
    });
    _scheduleBackup(interval);
  }







  // Methode zum Aktivieren/Ausschalten des automatischen Backups
  Future<void> _toggleAutomaticBackup(bool isEnabled) async {
    await _storageService.setAutomaticBackupEnabled(isEnabled);
    setState(() {
      _isAutomaticBackupEnabled = isEnabled;
      _backupStatus = isEnabled
          ? 'Automatisches Backup aktiviert.'
          : 'Automatisches Backup deaktiviert.';
    });
    if (isEnabled) {
      _scheduleBackup(_selectedInterval);
    } else {
      await Workmanager().cancelAll();
    }
  }

  // Methode zum Planen des automatischen Backups
  void _scheduleBackup(String interval) {
    // Entferne vorherige Aufgaben
    Workmanager().cancelAll();

    // Bestimme die Frequenz basierend auf dem ausgewählten Intervall
    Duration frequency;
    switch (interval) {
      case 'Täglich':
        frequency = const Duration(days: 1);
        break;
      case 'Wöchentlich':
        frequency = const Duration(days: 7);
        break;
      case 'Monatlich':
        frequency = const Duration(days: 30);
        break;
      default:
        frequency = const Duration(days: 1);
    }

    // Füge neue Aufgabe hinzu basierend auf dem Intervall
    Workmanager().registerPeriodicTask(
      "1",
      "automaticBackup",
      frequency: frequency,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backups',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Export Button
            ElevatedButton.icon(
              onPressed: _exportData,
              icon: const Icon(
                Icons.upload_file,
                color: Colors.white,
              ),
              label: const Text(
                'Daten exportieren',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            // Import Button
            ElevatedButton.icon(
              onPressed: _importData,
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
              label: const Text(
                'Daten importieren',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),

            // Switch zum Aktivieren/Ausschalten des automatischen Backups
            SwitchListTile(
              title: const Text(
                'Automatisches Backup aktivieren',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              value: _isAutomaticBackupEnabled,
              onChanged: (bool value) {
                _toggleAutomaticBackup(value);
              },
              activeColor: Colors.greenAccent,
              inactiveThumbColor: Colors.grey,
              activeTrackColor: Colors.green,
              inactiveTrackColor: Colors.grey[700],
            ),
            const SizedBox(height: 16),

            // Dropdown für Backup-Intervall (nur sichtbar, wenn automatisches Backup aktiviert ist)
            if (_isAutomaticBackupEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Automatisches Backup Intervall:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedInterval,
                    dropdownColor: Colors.grey, // Hintergrundfarbe des Dropdown-Menüs
                    items: <String>['Täglich', 'Wöchentlich', 'Monatlich']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _setBackupInterval(newValue);
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Backup Status
            Text(
              _backupStatus,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
