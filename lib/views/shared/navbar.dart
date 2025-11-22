import 'package:flutter/material.dart';
import '../feed/feed_view.dart';
import '../plan/plan_view.dart';
import '../remarkable/remarkable_view.dart';
import '../settings/settings_view.dart';

// Đây là StatefulWidget vì nó cần quản lý trạng thái của tab hiện tại
class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _currentIndex = 0; // State: Index của tab hiện tại

  // Danh sách các màn hình tương ứng với các tab
  final List<Widget> _screens = [
    const FeedView(), // Feed = isComplete == true
    const PlanView(), // Plan = isComplete == false
    const RemarkableView(), // Remarkable = isRemarkable == true
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // Hiển thị màn hình tương ứng với index hiện tại với animation
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _screens[_currentIndex],
      ),

      // Feature 3: BottomNavigationBar hiện đại với Light Theme
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.terrain_rounded,
                  label: 'Feed',
                  index: 0,
                  color: const Color(0xFF13EC37),
                ),
                _buildNavItem(
                  icon: Icons.map_rounded,
                  label: 'Plan',
                  index: 1,
                  color: const Color(0xFF3B82F6),
                ),
                _buildNavItem(
                  icon: Icons.star_rounded,
                  label: 'Remarkable',
                  index: 2,
                  color: const Color(0xFFFBBF24),
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 3,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom nav item với animation đẹp
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                size: isSelected ? 28 : 24,
                color: isSelected ? color : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF9CA3AF),
                fontFamily: 'PlusJakartaSans',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}