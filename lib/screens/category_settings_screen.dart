// screens/category_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/category_tab.dart';
import 'package:hive/hive.dart';



class CategorySettingsScreen extends StatefulWidget {
  final CategoryTab categoryTab;
  final Function(CategoryTab) onSave;

  const CategorySettingsScreen({
    super.key,
    required this.categoryTab,
    required this.onSave,
  });

  @override
  _CategorySettingsScreenState createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  late Box questionsBox;


  @override
  void initState() {
    super.initState();
    // Open the questions Hive box and load any saved questions
    questionsBox = Hive.box('questions');
    _loadSavedQuestions();
  }

  // Function to load saved questions from Hive
  void _loadSavedQuestions() {
    List<String>? savedQuestions = questionsBox.get(widget.categoryTab.name);
    if (savedQuestions != null && savedQuestions.isNotEmpty) {
      for (var question in savedQuestions) {
        _controllers.add(TextEditingController(text: question));
        _focusNodes.add(FocusNode());
      }
    } else {
      // If no saved questions, add an empty TextEditingController and FocusNode
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    });

    // Set the focus to the new text field
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(_focusNodes.last);
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _controllers.removeAt(index);
      _focusNodes.removeAt(index).dispose();
    });
  }

  void _saveQuestions() {
    final questions =
    _controllers.map((controller) => controller.text.trim()).toList();
    questionsBox.put(widget.categoryTab.name, questions);
    widget.onSave(widget.categoryTab..questions = questions);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.categoryTab.name, style: const TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green,),
            onPressed: _saveQuestions,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _controllers.length + 1,
        itemBuilder: (context, index) {
          if (index == _controllers.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  onPressed: _addQuestion,
                  icon: Icon(Icons.add, color: widget.categoryTab.color),
                  label: Text('Add Question', style: TextStyle(color: widget.categoryTab.color),),
                ),
              ),
            );
          }
          return ListTile(
            leading: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeQuestion(index),
            ),
            title: TextField(
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              cursorColor: Colors.white,
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(10)),
                hintText: 'Question ${index + 1}',
                labelStyle: TextStyle(color: Colors.grey[300]),
              ),
            ),
          );
        },
      ),
    );
  }
}
