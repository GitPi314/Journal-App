import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'models/category_tab.dart';
import 'widgets/calendar_timeline.dart';
import 'widgets/category_tabs.dart';
import 'widgets/note_section.dart';
import 'services/storage_service.dart';
import 'screens/category_settings_screen.dart';
import 'services/selection_tracker_service.dart';
import 'screens/questions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('journal_entries');
  await Hive.openBox('selection_tracker');
  await Hive.openBox('questions');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const JournalApp(),
    );
  }
}

class JournalApp extends StatefulWidget {
  const JournalApp({super.key});

  @override
  _JournalAppState createState() => _JournalAppState();
}

class _JournalAppState extends State<JournalApp> {
  DateTime _selectedDate = DateTime.now();
  List<CategoryTab> tabs = [
    CategoryTab(name: 'Journal', color: Colors.yellow, isSelected: true),
    CategoryTab(name: 'Gedanken', color: Colors.orange),
    CategoryTab(name: 'Ideen', color: Colors.red),
    CategoryTab(name: 'Erkenntnisse', color: Colors.blue),
    CategoryTab(name: 'Gefühle', color: Colors.green)
  ];
  late CategoryTab _selectedTab;
  final StorageService _storageService = StorageService();
  final SelectionTrackerService _selectionTracker = SelectionTrackerService();

  @override
  void initState() {
    super.initState();
    _selectedTab = tabs.firstWhere((tab) => tab.isSelected);
  }

  void _editCategory(CategoryTab tab) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategorySettingsScreen(
          categoryTab: tab,
          onSave: (updatedTab) {
            setState(() {
              final index = tabs.indexOf(tab);
              tabs[index] = updatedTab;
            });
          },
        ),
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _insertQuestionsAndAnswersIntoNoteSection(Map<String, String> answers) {
    String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';

    // Get existing content
    String existingContentJson = _storageService.getJournalEntry(key);

    // Initialize the document
    quill.Document document;
    if (existingContentJson.isNotEmpty) {
      document = quill.Document.fromJson(jsonDecode(existingContentJson));
    } else {
      document = quill.Document();
    }

    // Prepare the new content as a Delta
    var deltaList = Delta();

    answers.forEach((question, answer) {
      if (question.isNotEmpty) {
        // Insert question with bold formatting
        deltaList.insert('$question\n', {'bold': true});
      }

      if (answer.isNotEmpty) {
        // Insert answer as normal text
        deltaList.insert('$answer\n\n');
      }
    });

    // Append the new content to the document
    document.compose(deltaList, quill.ChangeSource.local);


    // Save the updated content
    String updatedContentJson = jsonEncode(document.toDelta().toJson());
    _storageService.saveJournalEntry(key, updatedContentJson);

    // Optionally refresh the NoteSection after saving
    setState(() {});
  }

  void _onTabSelected(CategoryTab tab) async {
    setState(() {
      for (var t in tabs) {
        t.isSelected = false;
      }
      tab.isSelected = true;
      _selectedTab = tab;
    });

    // Check if it's the first selection today
    final lastSelectedDate = _selectionTracker.getLastSelectedDate(tab.name);
    final today = DateTime.now();

    final isFirstSelectionToday = lastSelectedDate == null ||
        lastSelectedDate.year != today.year ||
        lastSelectedDate.month != today.month ||
        lastSelectedDate.day != today.day;

    if (isFirstSelectionToday && tab.questions.isNotEmpty) {
      // Show the questions screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuestionsScreen(
            categoryTab: tab,
            onConfirm: (answers) {
              // Process the answers
              _insertQuestionsAndAnswersIntoNoteSection(answers);
            },
          ),
        ),
      );
    }

    // Update the last selected date
    _selectionTracker.updateLastSelectedDate(tab.name, today);
  }

  void _onContentChanged(String content) {
    String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';
    _storageService.saveJournalEntry(key, content);
  }

  Future<String> _getInitialContent() async {
    String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';
    String content = _storageService.getJournalEntry(key);

    // If the content is null or empty, return an empty string
    if (content == null || content.isEmpty) {
      return '';  // Return a default empty value to avoid parsing issues
    }

    // Wrap JSON parsing in a try-catch to handle potential errors
    try {
      // Try to decode the content assuming it's valid JSON
      jsonDecode(content);
      return content;
    } catch (e) {
      print('Error parsing JSON: $e');
      // Return an empty string or some default valid content in case of error
      return '';
    }
  }


  void _addNewTab() {
    String tabName = '';
    Color tabColor = Colors.green;

    showDialog(
      context: context,
      builder: (context) {
        return AddTabDialog(
          onAdd: (name, color) {
            setState(() {
              tabs.add(CategoryTab(name: name, color: color));
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          CalendarTimeline(
            onDateSelected: _onDateSelected,
          ),
          // Remove extra vertical spacing if needed
          const SizedBox(height: 20,),
          CategoryTabs(
            tabs: tabs,
            onTabSelected: _onTabSelected,
            onAddTab: _addNewTab,
            onEditTab: _editCategory,
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: _getInitialContent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return NoteSection(
                    backgroundColor: _selectedTab.color,
                    onContentChanged: _onContentChanged,
                    initialContent: snapshot.data ?? '',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddTabDialog extends StatefulWidget {
  final Function(String, Color) onAdd;

  const AddTabDialog({super.key, required this.onAdd});

  @override
  _AddTabDialogState createState() => _AddTabDialogState();
}

class _AddTabDialogState extends State<AddTabDialog> {
  String tabName = '';
  Color tabColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Category'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                tabName = value;
              },
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              children: Colors.primaries.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      tabColor = color;
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      border: tabColor == color
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (tabName.isNotEmpty) {
              widget.onAdd(tabName, tabColor);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
