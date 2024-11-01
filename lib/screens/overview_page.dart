// overview_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:journal_app/screens/settings_screen.dart';
import 'dart:convert';
import '../services/storage_service.dart';

class OverviewPage extends StatefulWidget {
  final Function(String date, String category) onEntrySelected;

  const OverviewPage({super.key, required this.onEntrySelected});

  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  late TabController _tabController;
  Map<String, Map<String, String>> _entriesByCategory = {};
  final List<String> _categories = ['Journal', 'Gedanken', 'Ideen', 'Erkenntnisse', 'Gefühle'];
  Map<String, Set<String>> _markedDaysByCategory = {};
  bool _showOnlyMarked = false;
  final StorageService _storageService = StorageService();
  late Box _markedDaysBox;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _markedDaysBox = Hive.box('marked_days');
    _loadMarkedDays();
    _loadEntries();
  }

  void _loadMarkedDays() {
    _markedDaysByCategory = {};
    for (String category in _categories) {
      List<dynamic>? markedDates = _markedDaysBox.get(category);
      if (markedDates != null) {
        _markedDaysByCategory[category] = markedDates.cast<String>().toSet();
      } else {
        _markedDaysByCategory[category] = {};
      }
    }
  }

  bool _isDayMarked(String category, String date) {
    if (!_markedDaysByCategory.containsKey(category)) {
      _markedDaysByCategory[category] = {};
    }
    return _markedDaysByCategory[category]!.contains(date);
  }

  void _toggleDayMarked(String category, String date) {
    setState(() {
      if (!_markedDaysByCategory.containsKey(category)) {
        _markedDaysByCategory[category] = {};
      }
      if (_markedDaysByCategory[category]!.contains(date)) {
        _markedDaysByCategory[category]!.remove(date);
      } else {
        _markedDaysByCategory[category]!.add(date);
      }
      // Save the updated marked days to Hive
      _markedDaysBox.put(category, _markedDaysByCategory[category]!.toList());
    });
  }

  void _loadEntries() {
    Map<String, Map<String, String>> entries = {};

    var journalBox = Hive.box('journal_entries');

    for (var key in journalBox.keys) {
      String keyString = key.toString();
      List<String> parts = keyString.split('_');
      if (parts.length < 2) continue; // Skip invalid keys
      String date = parts[0];
      String category = parts[1];

      String content = _storageService.getJournalEntry(keyString);

      if (!entries.containsKey(category)) {
        entries[category] = {};
      }

      entries[category]![date] = content;
    }

    setState(() {
      _entriesByCategory = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Übersicht',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: 'Einstellungen',
            ),
          ],
          titleSpacing: MediaQuery.of(context).size.width -285,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.greenAccent, width: 3))),
            indicatorColor: Colors.greenAccent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white, // Color of the selected tab's text
            unselectedLabelColor: Colors.grey, // Color of the unselected tab's text
            labelStyle: const TextStyle(
              fontSize: 21, // Font size for the selected tab
              fontWeight: FontWeight.bold, // Font weight for the selected tab
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16, // Font size for unselected tabs
              fontWeight: FontWeight.normal, // Font weight for unselected tabs
            ),
            tabs: _categories.map((category) {
              return Tab(
                text: category,
              );
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            return _buildCategoryTab(category);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    return Column(
      children: [
        if (category == 'Journal' || category == 'Gefühle')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Favoriten: ',
                  style: TextStyle(fontSize: 20, color: Colors.greenAccent),
                ),
                Switch(
                  activeColor: Colors.greenAccent,
                  activeTrackColor: Colors.green,
                  value: _showOnlyMarked,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyMarked = value;
                    });
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: _buildEntriesList(category),
        ),
      ],
    );
  }

  Widget _buildEntriesList(String category) {
    Map<String, String>? entries = _entriesByCategory[category];
    List<String> sortedDates = entries != null ? entries.keys.toList() : [];
    sortedDates.sort((a, b) => b.compareTo(a)); // Sort dates descending

    if (entries == null || entries.isEmpty) {
      return const Center(
        child: Text(
          'Keine Einträge',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String dateString = sortedDates[index];
        DateTime date;
        try {
          date = DateTime.parse(dateString);
        } catch (e) {
          print('Ungültiges Datum: $dateString');
          return Container(); // Überspringe ungültige Daten
        }
        String key = '${dateString}_$category';

        String content = entries[dateString]!;

        // Beschreibung für das Datum und die Kategorie abrufen
        String description = '';
        if (category == 'Journal' || category == 'Gefühle') {
          description = _storageService.getDescription(key);
        }

        // Filterung nach markierten Tagen
        if (_showOnlyMarked && !_isDayMarked(category, dateString)) {
          return Container(); // Überspringe unmarkierte Tage, wenn der Filter aktiv ist
        }

        bool isMarked = _isDayMarked(category, dateString);

        String plainText = '';
        List<String> audioTitles = [];

        try {
          quill.Document doc = quill.Document.fromJson(jsonDecode(content));
          plainText = doc.toPlainText().trim();

          // Extrahiere Audio-Titel
          for (var op in doc.toDelta().toList()) {
            if (op.isInsert && op.value is Map && (op.value as Map).containsKey('audio')) {
              String dataString = op.value['audio'];
              print('Audio Embed gefunden: $dataString');
              Map<String, dynamic> dataMap = jsonDecode(dataString);
              String title = dataMap['name'] ?? 'Audio';
              audioTitles.add(title);
              print('Gefundener Audio-Titel: $title');
            }
          }
        } catch (e) {
          // Falls ein Fehler auftritt, verwenden wir den Originalinhalt
          plainText = content;
          print('Fehler beim Parsen des Quill-Dokuments: $e');
        }

        return ListTile(
          title: Text(
            _dateFormat.format(date),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: category == 'Journal' || category == 'Gefühle'
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
              if (audioTitles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: audioTitles.map((title) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          )
              : Text(
            plainText.length > 100 ? '${plainText.substring(0, 100)}...' : plainText,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          trailing: category == 'Journal' || category == 'Gefühle'
              ? IconButton(
            icon: Icon(
              isMarked ? Icons.bookmark : Icons.bookmark_border,
              color: isMarked ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              _toggleDayMarked(category, dateString);
            },
          )
              : null,
          onTap: () {
            _navigateToNoteView(dateString, category);
          },
        );
      },
    );
  }

  void _navigateToNoteView(String date, String category) {
    widget.onEntrySelected(date, category);
    Navigator.of(context).pop(); // Schließt die Übersichtseite
  }
}
