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
  await Hive.openBox('marked_days');
  await Hive.openBox('descriptions');
  await Hive.openBox('audio_notes');
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
  final GlobalKey<NoteSectionState> _noteSectionKey = GlobalKey<NoteSectionState>();
  bool _isRecordingInProgress = false;
  Future<List<String>>? _initialContentFuture;
  bool _isRecording = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = tabs.firstWhere((tab) => tab.isSelected);
    _loadInitialContent();
  }

  void _loadInitialContent() {
    setState(() {
      _initialContentFuture = Future.wait([
        _getInitialContent(),
        _getInitialDescription(),
      ]);
    });
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
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
    _loadInitialContent(); // Initialen Inhalt neu laden
  }

  void _insertQuestionsAndAnswersIntoNoteSection(Map<String, String> answers) {
    String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';

    String existingContentJson = _storageService.getJournalEntry(key);

    quill.Document document;
    if (existingContentJson.isNotEmpty) {
      document = quill.Document.fromJson(jsonDecode(existingContentJson));
    } else {
      document = quill.Document();
    }

    var deltaList = Delta();

    answers.forEach((question, answer) {
      if (question.isNotEmpty) {
        deltaList.insert('$question\n', {'bold': true});
      }

      if (answer.isNotEmpty) {
        deltaList.insert('$answer\n\n');
      }
    });

    document.compose(deltaList, quill.ChangeSource.local);

    String updatedContentJson = jsonEncode(document.toDelta().toJson());
    _storageService.saveJournalEntry(key, updatedContentJson);

    _loadInitialContent(); // Inhalt neu laden
  }

  void _onTabSelected(CategoryTab tab) async {
    setState(() {
      for (var t in tabs) {
        t.isSelected = false;
      }
      tab.isSelected = true;
      _selectedTab = tab;
      _selectedIndex = tabs.indexOf(tab);
    });

    _loadInitialContent(); // Initialen Inhalt neu laden

    final questionsBox = Hive.box('questions');
    List<String>? loadedQuestions = questionsBox.get(tab.name);

    setState(() {
      if (loadedQuestions != null) {
        _selectedTab.questions = loadedQuestions;
      } else {
        _selectedTab.questions = [];
      }
    });

    final DateTime? lastOpenedDate = await _selectionTracker.getLastOpenedDate(tab.name);
    final today = DateTime.now();

    final isFirstSelectionToday = lastOpenedDate == null ||
        lastOpenedDate.year != today.year ||
        lastOpenedDate.month != today.month ||
        lastOpenedDate.day != today.day;

    if (isFirstSelectionToday && _selectedTab.questions.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuestionsScreen(
            categoryTab: _selectedTab,
            onConfirm: (answers) {
              _insertQuestionsAndAnswersIntoNoteSection(answers);
            },
          ),
        ),
      );
      await _selectionTracker.updateLastOpenedDate(tab.name, today);
    }
  }

  void _onContentChanged(String content) {
    String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';
    _storageService.saveJournalEntry(key, content);
  }

  void _onDescriptionChanged(String description) {
    if (_selectedTab.name == 'Journal' || _selectedTab.name == 'Gefühle') {
      String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';
      _storageService.saveDescription(key, description);
    }
  }

  Future<String> _getInitialDescription() async {
    if (_selectedTab.name == 'Journal' || _selectedTab.name == 'Gefühle') {
      String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';
      return Future.value(_storageService.getDescription(key));
    } else {
      return Future.value('');
    }
  }

  Future<String> _getInitialContent() async {
    String key = '${_selectedDate.toString().split(' ')[0]}_${_selectedTab.name}';
    String content = _storageService.getJournalEntry(key);

    if (content.isEmpty) {
      return '';
    }

    try {
      jsonDecode(content);
      return content;
    } catch (e) {
      print('Error parsing JSON: $e');
      return '';
    }
  }

  void _addNewTab() {
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

  void _onOverviewEntrySelected(String date, String category) {
    setState(() {
      _selectedDate = DateTime.parse(date);
      _selectedTab = tabs.firstWhere((tab) => tab.name == category);
      for (var tab in tabs) {
        tab.isSelected = tab.name == category;
      }
    });
    _loadInitialContent(); // Initialen Inhalt neu laden
  }

  void _handleFabPressed() {
    if (_selectedTab.questions.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuestionsScreen(
            categoryTab: _selectedTab,
            onConfirm: (answers) {
              _insertQuestionsAndAnswersIntoNoteSection(answers);
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CategorySettingsScreen(
            categoryTab: _selectedTab,
            onSave: (updatedTab) {
              setState(() {
                final index = tabs.indexOf(_selectedTab);
                tabs[index] = updatedTab;
                _selectedTab = updatedTab;
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            CalendarTimeline(
              onDateSelected: _onDateSelected,
              onOverviewEntrySelected: _onOverviewEntrySelected,
            ),
            const SizedBox(height: 25),
            CategoryTabs(
              tabs: tabs,
              onTabSelected: _onTabSelected,
              onAddTab: _addNewTab,
              onEditTab: _editCategory,
              selectedIndex: _selectedIndex,
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _initialContentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    String initialContent = snapshot.data?[0] ?? '';
                    String initialDescription = snapshot.data?[1] ?? '';
                    return NoteSection(
                      key: _noteSectionKey,
                      backgroundColor: _selectedTab.color,
                      onContentChanged: _onContentChanged,
                      initialContent: initialContent,
                      initialDescription: initialDescription,
                      onDescriptionChanged: _onDescriptionChanged,
                      categoryName: _selectedTab.name,
                      isRecording: _isRecording,
                      onStartRecording: _startRecording,
                      onStopRecording: _stopRecording,
                      onRecordingStateChanged: (isRecording) {
                        setState(() {
                          _isRecordingInProgress = isRecording;
                        });
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isRecordingInProgress
            ? null
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 55,
              child: FloatingActionButton(
                heroTag: 'questionFab',
                onPressed: _handleFabPressed,
                backgroundColor: _selectedTab.color,
                child: const Icon(
                  Icons.question_answer,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // New FAB for audio recording
            FloatingActionButton(
              heroTag: 'audioFab',
              onPressed: () {
                _noteSectionKey.currentState?.onStartRecording();
              },
              backgroundColor: _selectedTab.color,
              child: const Icon(Icons.mic),
            ),
          ],
        ),
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
