// overview_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class OverviewPage extends StatefulWidget {
  final Function(String date, String category) onEntrySelected;

  const OverviewPage({Key? key, required this.onEntrySelected}) : super(key: key);

  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> with SingleTickerProviderStateMixin {
  final Box _journalBox = Hive.box('journal_entries');
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  late TabController _tabController;
  Map<String, Map<String, String>> _entriesByCategory = {};
  final List<String> _categories = ['Journal', 'Gedanken', 'Ideen', 'Erkenntnisse', 'Gefühle'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  void _loadEntries() {
    Map<String, Map<String, String>> entries = {};

    for (var key in _journalBox.keys) {
      String dateKey = key.toString();
      List<String> parts = dateKey.split('_');
      if (parts.length < 2) continue; // Skip invalid keys
      String date = parts[0];
      String category = parts[1];
      String content = _journalBox.get(key);

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
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text('Overview', style: TextStyle(color: Colors.white),),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.greenAccent,
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
    if (category == 'Journal' || category == 'Gefühle') {
      // Overview without displaying entries
      return _buildOverviewTab(category);
    } else {
      // Display dates and entries
      return _buildEntriesTab(category);
    }
  }

  Widget _buildOverviewTab(String category) {
    Map<String, String>? entries = _entriesByCategory[category];
    List<String> sortedDates = entries != null ? entries.keys.toList() : [];
    sortedDates.sort((a, b) => b.compareTo(a)); // Sort dates descending

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        // Indicate whether an entry exists on that day
        bool hasEntry = entries![date] != null && entries[date]!.isNotEmpty;

        return ListTile(
          title: Text(
            _dateFormat.format(DateTime.parse(date)),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          trailing: hasEntry
              ? const Icon(Icons.circle, color: Colors.green, size: 12)
              : const Icon(Icons.circle_outlined, color: Colors.grey, size: 12),
          onTap: hasEntry
              ? () {
            // Navigate to note view for that date and category
            _navigateToNoteView(date, category);
          }
              : null,
        );
      },
    );
  }

  Widget _buildEntriesTab(String category) {
    Map<String, String>? entries = _entriesByCategory[category];
    if (entries == null || entries.isEmpty) {
      return const Center(child: Text('No entries', style: TextStyle(color: Colors.white),));
    }

    List<String> sortedDates = entries.keys.toList();
    sortedDates.sort((a, b) => b.compareTo(a)); // Sort dates descending

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        String content = entries[date]!;

        return ExpansionTile(
          title: Text(
            _dateFormat.format(DateTime.parse(date)),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          children: [
            ListTile(
              title: Text(
                content.length > 100 ? content.substring(0, 100) + '...' : content,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              onTap: () {
                // Navigate to note view for that date and category
                _navigateToNoteView(date, category);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToNoteView(String date, String category) {
    widget.onEntrySelected(date, category);
    Navigator.of(context).pop(); // Close the overview page
  }
}
