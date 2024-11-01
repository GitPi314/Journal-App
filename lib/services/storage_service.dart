import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';

class StorageService {
  final String journalEntriesBoxName = 'journal_entries';
  final String descriptionsBoxName = 'descriptions';
  final String audioNotesBoxName = 'audio_notes';
  final String settingsBoxName = 'settings';

  // Speichern des Journal-Eintrags pro Kategorie
  void saveJournalEntry(String category, String content) {
    var box = Hive.box(journalEntriesBoxName);
    box.put(category, content);
  }

  // Abrufen des Journal-Eintrags für eine Kategorie
  String getJournalEntry(String category) {
    var box = Hive.box(journalEntriesBoxName);
    return box.get(category, defaultValue: '');
  }

  // Speichern der Beschreibung pro Kategorie
  void saveDescription(String category, String description) {
    var box = Hive.box(descriptionsBoxName);
    box.put(category, description);
  }

  // Abrufen der Beschreibung für eine Kategorie
  String getDescription(String category) {
    var box = Hive.box(descriptionsBoxName);
    return box.get(category, defaultValue: '');
  }

  // Hinzufügen einer Audio-Notiz pro Kategorie
  void addAudioNote(String category, String audioNoteJson) {
    var box = Hive.box(audioNotesBoxName);
    List<String> audioNotesJson = box.get(category, defaultValue: []).cast<String>();
    audioNotesJson.add(audioNoteJson);
    box.put(category, audioNotesJson);
  }

  // Abrufen der Audio-Notizen für eine Kategorie
  List<String> getAudioNotes(String category) {
    var box = Hive.box(audioNotesBoxName);
    return box.get(category, defaultValue: []).cast<String>();
  }


  // Exportiere alle relevanten Boxen in eine JSON-Datei
  Future<void> exportData(String backupPath) async {
    Map<String, dynamic> data = {};

    // Exportiere jede relevante Box
    data[journalEntriesBoxName] = Map<String, dynamic>.from(Hive.box(journalEntriesBoxName).toMap());
    data[descriptionsBoxName] = Map<String, dynamic>.from(Hive.box(descriptionsBoxName).toMap());
    data[audioNotesBoxName] = Map<String, dynamic>.from(Hive.box(audioNotesBoxName).toMap());
    data[settingsBoxName] = Map<String, dynamic>.from(Hive.box(settingsBoxName).toMap());

    // Schreibe die Daten in die Datei
    File backupFile = File(backupPath);
    await backupFile.writeAsString(jsonEncode(data));
  }

  // Importiere alle relevanten Boxen aus einer JSON-Datei
  Future<void> importData(String backupPath) async {
    File backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw Exception('Backup-Datei existiert nicht.');
    }

    String content = await backupFile.readAsString();
    Map<String, dynamic> data = jsonDecode(content);

    // Importiere jede relevante Box
    var journalBox = Hive.box(journalEntriesBoxName);
    var descriptionsBox = Hive.box(descriptionsBoxName);
    var audioNotesBox = Hive.box(audioNotesBoxName);
    var settingsBox = Hive.box(settingsBoxName);

    // Leere die Boxen bevor du neue Daten hinzufügst
    await journalBox.clear();
    await descriptionsBox.clear();
    await audioNotesBox.clear();
    await settingsBox.clear();

    // Füge die importierten Daten hinzu
    journalBox.putAll(Map<String, dynamic>.from(data[journalEntriesBoxName] ?? {}));
    descriptionsBox.putAll(Map<String, dynamic>.from(data[descriptionsBoxName] ?? {}));
    audioNotesBox.putAll(Map<String, dynamic>.from(data[audioNotesBoxName] ?? {}));
    settingsBox.putAll(Map<String, dynamic>.from(data[settingsBoxName] ?? {}));
  }

  // Einstellungen für Splash-Screen verwalten
  Future<bool> getSplashScreenSetting() async {
    var box = Hive.box(settingsBoxName);
    return box.get('splash_enabled', defaultValue: true);
  }

  Future<void> setSplashScreenSetting(bool value) async {
    var box = Hive.box(settingsBoxName);
    await box.put('splash_enabled', value);
  }

  Future<bool> isAutomaticBackupEnabled() async {
    var box = Hive.box(settingsBoxName);
    return box.get('automatic_backup_enabled', defaultValue: false);
  }

  Future<void> setAutomaticBackupEnabled(bool value) async {
    var box = Hive.box(settingsBoxName);
    await box.put('automatic_backup_enabled', value);
  }

  Future<String> getBackupInterval() async {
    var box = Hive.box(settingsBoxName);
    return box.get('backup_interval', defaultValue: 'Täglich');
  }

  Future<void> setBackupInterval(String interval) async {
    var box = Hive.box(settingsBoxName);
    await box.put('backup_interval', interval);
  }
}
