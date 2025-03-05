import 'package:flutter/material.dart';
import 'tabs/all_tab.dart';
import 'tabs/content_tab.dart';
import 'tabs/health_tab.dart';
import 'tabs/sage_time_tab.dart';

class MysteryPage extends StatelessWidget {
  const MysteryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: '全部'),
              Tab(text: '内容项'),
              Tab(text: '大健康'),
              Tab(text: '贤者时间'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AllTabPage(),
            ContentTabPage(),
            HealthTabPage(),
            SageTimeTabPage(),
          ],
        ),
      ),
    );
  }
} 