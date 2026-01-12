import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/score_provider.dart';
import 'package:teacher_tools/screens/score/tabs/score_list_tab.dart';
import 'package:teacher_tools/screens/score/tabs/statistics_tab.dart';
import 'package:teacher_tools/screens/score/tabs/trend_chart_tab.dart';

/// 学生成绩主页面
class StudentScoreScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentScoreScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentScoreScreen> createState() => _StudentScoreScreenState();
}

class _StudentScoreScreenState extends State<StudentScoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 预加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScoreProvider>().loadAllData(widget.studentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} 的成绩'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '成绩列表', icon: Icon(Icons.list)),
            Tab(text: '统计分析', icon: Icon(Icons.bar_chart)),
            Tab(text: '趋势图表', icon: Icon(Icons.show_chart)),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ScoreListTab(studentId: widget.studentId),
          StatisticsTab(studentId: widget.studentId),
          TrendChartTab(studentId: widget.studentId),
        ],
      ),
    );
  }
}
