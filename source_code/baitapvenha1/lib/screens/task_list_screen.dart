import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:baitapvenha1/ models/task.dart';
import 'package:baitapvenha1/services/api_service.dart';
import 'package:baitapvenha1/screens/task_detail_screen.dart';
import 'package:baitapvenha1/ widgets/empty_view.dart';
import 'package:baitapvenha1/services/deleted_store.dart';

const Color kPrimary = Color(0xFF2B6CEA);
const Color kBg = Color(0xFFF7F8FB);

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService api = ApiService();
  List<Task> _tasks = [];
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() { _loading = true; });
    try {
      print('=== START _loadTasks (NO FILTER) ===');
      final list = await api.fetchTasks();
      print('Fetched from API: ${list.length} items');
      for (var t in list) {
        print('API item -> id=${t.id} title="${t.title}"');
      }

      // TEMP: do not use DeletedStore filter so we can check UI
      setState(() {
        _tasks = list;
      });
    } catch (e, st) {
      print('Error loading tasks: $e\n$st');
    } finally {
      setState(() { _loading = false; });
      print('=== END _loadTasks (NO FILTER) ===');
    }
  }

  Future<void> _refresh() async => await _loadTasks();

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd').format(dt.toLocal());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFFFFE5E5);
      case 'pending':
        return const Color(0xFFEFF7D1);
      default:
        return const Color(0xFFE6F0FF);
    }
  }

  Color _statusAccent(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFFDB5C6C);
      case 'pending':
        return const Color(0xFF4BA55B);
      default:
        return const Color(0xFF2B6CEA);
    }
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final bool isActive = _selectedIndex == index;
    final Color activeColor = kPrimary;
    final Color inactiveColor = Colors.grey.shade500;

    return IconButton(
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      icon: Icon(
        icon,
        color: isActive ? activeColor : inactiveColor,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          color: kBg,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Logo (Image.asset với errorBuilder fallback)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/img/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            // fallback nếu không tìm thấy ảnh hoặc lỗi
                            return const Center(
                              child: Icon(Icons.task_alt, size: 32, color: Colors.black26),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title & subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'SmartTasks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A simple and efficient to-do app',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    // Action icons
                    IconButton(
                      tooltip: 'Reset deleted',
                      icon: const Icon(Icons.autorenew),
                      onPressed: () async {
                        await DeletedStore.reset();
                        await _loadTasks();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DeletedStore reset')));
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {
                        // TODO: mở màn hình thông báo
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refresh,
        child: _tasks.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 24),
            EmptyView(),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _tasks.length,
          itemBuilder: (context, i) {
            final t = _tasks[i];
            final bg = _statusColor(t.status);
            final accent = _statusAccent(t.status);
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push<dynamic>(
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)),
                );
                if (result is int) {
                  setState(() {
                    _tasks.removeWhere((e) => e.id == result);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa task')));
                } else if (result == true) {
                  _loadTasks();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.check, size: 20),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600, color: accent)),
                              Text(t.status, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(_formatDate(t.dueDate), style: const TextStyle(color: Colors.black54)),
                              const SizedBox(width: 10),
                            ])
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo task'))),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildNavIcon(Icons.home_outlined, 0),
                    _buildNavIcon(Icons.calendar_month_outlined, 1),
                  ],
                ),
                Row(
                  children: [
                    _buildNavIcon(Icons.list_alt, 2),
                    _buildNavIcon(Icons.settings_outlined, 3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
