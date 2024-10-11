import 'package:hive/hive.dart';

class StorageService {
  final String boxName = 'journal_entries';

  void saveJournalEntry(String key, String content) {
    var box = Hive.box(boxName);
    box.put(key, content);
  }

  String getJournalEntry(String key) {
    var box = Hive.box(boxName);
    return box.get(key, defaultValue: '');
  }
}
