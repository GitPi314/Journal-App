import 'package:flutter/material.dart';
import '../models/category_tab.dart';

class CategoryTabs extends StatefulWidget {
  final List<CategoryTab> tabs;
  final Function(CategoryTab) onTabSelected;
  final Function onAddTab;
  final Function(CategoryTab) onEditTab;

  const CategoryTabs({
    super.key,
    required this.tabs,
    required this.onTabSelected,
    required this.onAddTab,
    required this.onEditTab,
  });

  @override
  _CategoryTabsState createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 53,
      child: Stack(
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.tabs.length + 1,
            itemBuilder: (context, index) {
              // Handle the add button at the end of the tabs
              if (index == widget.tabs.length) {
                return GestureDetector(
                  onTap: () {
                    widget.onAddTab();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                );
              }

              CategoryTab tab = widget.tabs[index];
              bool isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onTabSelected(tab);
                },
                onLongPress: () {
                  widget.onEditTab(tab); // Call a new callback
                },
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Slight overlap for unselected tabs
                    Transform.translate(
                      offset: Offset(isSelected ? 0 : -10, 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: isSelected ? 150 : 75,  // Expand when selected
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? tab.color.withOpacity(0.9) : tab.color.withOpacity(0.6),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : 0.0,
                            child: Text(
                              tab.name,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: isSelected ? 16 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
