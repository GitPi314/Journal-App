import 'package:flutter/material.dart';

class CategoryTab {
  String name;
  Color color;
  bool isSelected;
  List<String> questions;

  CategoryTab({
    required this.name,
    required this.color,
    this.isSelected = false,
    List<String>? questions, // Use `List<String>?` here
  }) : questions = questions ?? [];
}
