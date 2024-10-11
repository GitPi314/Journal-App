// screens/questions_screen.dart
import 'package:flutter/material.dart';
import '../models/category_tab.dart';

class QuestionsScreen extends StatefulWidget {
  final CategoryTab categoryTab;
  final Function(Map<String, String>) onConfirm;

  const QuestionsScreen({
    super.key,
    required this.categoryTab,
    required this.onConfirm,
  });

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var question in widget.categoryTab.questions) {
      _controllers[question] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final answers = <String, String>{};
    _controllers.forEach((question, controller) {
      answers[question] = controller.text.trim();
    });
    widget.onConfirm(answers);
    Navigator.of(context).pop();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Semi-transparent background
      backgroundColor: Colors.black54,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancel,
                  ),
                ),
                // Questions
                ...widget.categoryTab.questions.map((question) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controllers[question],
                          cursorColor: Colors.black,
                          decoration:  InputDecoration(
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.categoryTab.color, width: 2), borderRadius: BorderRadius.circular(6)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            hintText: 'Your answer...',
                          ),
                          maxLines: null,
                        ),
                      ],
                    ),
                  );
                }),
                // Confirm button
                ElevatedButton.icon(
                  style: const ButtonStyle(),
                  onPressed: _confirm,
                  icon: const Icon(Icons.check, ),
                  label: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
