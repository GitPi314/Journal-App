import 'package:hive/hive.dart';

class StorageService {
  final String boxName = 'journal_entries';
  final String descriptionsBoxName = 'descriptions';

  void saveJournalEntry(String key, String content) {
    var box = Hive.box(boxName);
    box.put(key, content);
  }

  String getJournalEntry(String key) {
    var box = Hive.box(boxName);
    return box.get(key, defaultValue: '');
  }

  void saveDescription(String key, String description) {
    var box = Hive.box(descriptionsBoxName);
    box.put(key, description);
  }

  String getDescription(String key) {
    var box = Hive.box(descriptionsBoxName);
    return box.get(key, defaultValue: '');
  }

  void saveAudioNotes(String key, List<String> audioNotesJson) {
    var box = Hive.box('audio_notes');
    box.put(key, audioNotesJson);
  }

  List<String> getAudioNotes(String key) {
    var box = Hive.box('audio_notes');
    return box.get(key, defaultValue: []).cast<String>();
  }
}
