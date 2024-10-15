import 'package:hive/hive.dart';

class SelectionTrackerService {
  late Box _box;

  // Initialize the Hive box asynchronously
  Future<void> init() async {
    _box = await Hive.openBox('selection_tracker');
  }

  // Update the last selected date for a specific category
  Future<void> updateLastOpenedDate(String categoryName, DateTime date) async {
    await _box.put(categoryName, date.toIso8601String());
  }

  // Retrieve the last selected date for a specific category
  DateTime? getLastOpenedDate(String categoryName) {
    final dateStr = _box.get(categoryName);
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
    await _box.delete(categoryName);
  }
}
