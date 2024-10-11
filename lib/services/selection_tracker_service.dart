// services/selection_tracker_service.dart
import 'package:hive/hive.dart';

class SelectionTrackerService {
  final Box _box = Hive.box('selection_tracker');

  Future<void> updateLastSelectedDate(String categoryName, DateTime date) async {
    await _box.put(categoryName, date.toIso8601String());
  }

  DateTime? getLastSelectedDate(String categoryName) {
    final dateStr = _box.get(categoryName);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }
}
