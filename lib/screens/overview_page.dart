// overview_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category_tab.dart';
import 'package:intl/intl.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final Box _journalBox = Hive.box('journal_entries');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  Map<String, Map<String, dynamic>> _entriesByDate = {};

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    Map<String, Map<String, dynamic>> entries = {};

    for (var key in _journalBox.keys) {
      String dateKey = key.toString();
      String date = dateKey.split('_')[0];
      String category = dateKey.split('_')[1];
      String content = _journalBox.get(key);

      if (!entries.containsKey(date)) {
        entries[date] = {};
      }

      entries[date]![category] = content;
    }

    setState(() {
      _entriesByDate = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedDates = _entriesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort dates descending

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
      ),
      body: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          String date = sortedDates[index];
          Map<String, dynamic> categories = _entriesByDate[date]!;

          return ExpansionTile(
            title: Text(_dateFormat.format(DateTime.parse(date))),
            children: categories.entries.map((entry) {
              String category = entry.key;
              String content = entry.value;

              return ListTile(
                title: Text(category),
                subtitle: Text(
                  content.length > 50 ? content.substring(0, 50) + '...' : content,
                ),
                onTap: () {
                  // Optional: Navigate to a detailed view of the entry
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
