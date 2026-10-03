import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Health'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
    (Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'Coach'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xD9F8FCFA),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A073E38),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final selected = index == selectedIndex;
                final item = items[index];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: selected
                            ? const [
                                BoxShadow(
                                  color: Color(0x16073E38),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? item.$2 : item.$1,
                            color: selected
                                ? AppColors.primary
                                : AppColors.mutedText,
                            size: 21,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
