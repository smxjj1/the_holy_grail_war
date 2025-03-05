import 'package:flutter/material.dart';
import 'mystery_page.dart';
import 'device_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const MysteryPage(),
    const DevicePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: ThemeData(
          // 设置水波纹颜色为透明
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // 设置底部导航栏样式
          backgroundColor: const Color(0xFF1A1B1E), // 深色背景
          selectedItemColor: const Color(0xFF00BCD4), // 选中项的颜色为青色
          unselectedItemColor: Colors.grey, // 未选中项的颜色为灰色
          type: BottomNavigationBarType.fixed, // 固定样式
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.question_mark),
              label: '神秘',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: '设备',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
} 