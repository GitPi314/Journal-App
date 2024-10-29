import 'package:hive/hive.dart';

class StorageService {
  final String journalEntriesBoxName = 'journal_entries';
  final String descriptionsBoxName = 'descriptions';
  final String audioNotesBoxName = 'audio_notes';

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
}
