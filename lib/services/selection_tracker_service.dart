import 'package:hive/hive.dart';

class SelectionTrackerService {
  // Singleton-Instanz
  static final SelectionTrackerService _instance = SelectionTrackerService._internal();

  factory SelectionTrackerService() {
    return _instance;
  }

  SelectionTrackerService._internal();

  Box? _box;

  // Private Methode, um sicherzustellen, dass _box initialisiert ist
  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox('selection_tracker');
    }
    return _box!;
  }

  // Update the last selected date for a specific category
  Future<void> updateLastOpenedDate(String categoryName, DateTime date) async {
    final box = await _getBox();
    await box.put(categoryName, date.toIso8601String());
  }

  // Retrieve the last selected date for a specific category
  Future<DateTime?> getLastOpenedDate(String categoryName) async {
    final box = await _getBox();
    final dateStr = box.get(categoryName);
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        // Handle any parsing errors
        return null;
      }
    }
    return null;
  }

  // Clear the last selected date for a specific category (if needed)
  Future<void> clearLastSelectedDate(String categoryName) async {
    final box = await _getBox();
    await box.delete(categoryName);
  }
}
