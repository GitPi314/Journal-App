import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/overview_page.dart'; // Import the OverviewPage here

class CalendarTimeline extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final Function(String date, String category) onOverviewEntrySelected;

  const CalendarTimeline({
    Key? key,
    required this.onDateSelected,
    required this.onOverviewEntrySelected,
  }) : super(key: key);

  @override
  _CalendarTimelineState createState() => _CalendarTimelineState();
}

class _CalendarTimelineState extends State<CalendarTimeline> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dayFormat = DateFormat('EEE');
  final DateFormat _dateFormat = DateFormat('d');
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _centerCurrentDate() {
    int currentDateIndex = DateTime.now().weekday - 1;
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = 60.0;

    double targetScrollOffset =
        (currentDateIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    _scrollController.animateTo(
      targetScrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<DateTime> _getCurrentWeekDates() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime monday = now.subtract(Duration(days: currentWeekday - 1));

    return List.generate(
        7, (index) => monday.add(Duration(days: index))); // Monday to Sunday
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> currentWeek = _getCurrentWeekDates();

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: currentWeek.length,
              itemBuilder: (context, index) {
                DateTime date = currentWeek[index];
                bool isSelected = _isSameDate(_selectedDate, date);
                bool isToday = _isSameDate(DateTime.now(), date);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected(date);
                  },
                  child: Container(
                    width: 50,
                    margin:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent, //isSelected ? (isToday ? Colors.greenAccent : Colors.transparent) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      border: isSelected
                          ? Border.all( color: Colors.greenAccent, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayFormat.format(date),
                          style: TextStyle(
                            color: isToday ? Colors.green : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _dateFormat.format(date),
                          style: TextStyle(
                            color: isToday ? Colors.green : Colors.white,
                            fontSize: isSelected || isToday ? 18 : 16,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Add the overview icon button to navigate to the overview page
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OverviewPage(
                    onEntrySelected: widget.onOverviewEntrySelected,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
