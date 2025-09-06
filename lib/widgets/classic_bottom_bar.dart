import 'package:flutter/material.dart';

class ClassicBottomItem {
  final IconData icon;
  final String label;
  const ClassicBottomItem({required this.icon, required this.label});
}

class ClassicBottomBar extends StatelessWidget {
  final List<ClassicBottomItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const ClassicBottomBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selectedColor = Colors.white;
    final unselectedColor = Colors.white70;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3C3C3C), Color(0xFF1F1F1F)],
        ),
        border: Border(top: BorderSide(color: Color(0x66000000))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            items[i].icon,
                            color: i == currentIndex ? selectedColor : unselectedColor,
                            size: 24,
                          ),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              color: i == currentIndex ? selectedColor : unselectedColor,
                              fontSize: 11,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

