import 'dart:ui';

class CategoryTab {
  String name;
  Color color;
  bool isSelected;
  List<String> questions;

  CategoryTab({
    required this.name,
    required this.color,
    this.isSelected = false,
    List<String>? questions,
  }) : questions = questions ?? [];
}
