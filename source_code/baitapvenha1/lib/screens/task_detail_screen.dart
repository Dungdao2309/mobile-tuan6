// lib/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baitapvenha1/ models/task.dart';
import 'package:baitapvenha1/services/api_service.dart';
import 'package:baitapvenha1/services/deleted_store.dart';

const Color kPinkBox = Color(0xFFF7D8DA);
const Color kLightGrey = Color(0xFFF1F2F5);

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService api = ApiService();
  late Future<Task> _futureDetail;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _futureDetail = api.fetchTaskDetail(widget.taskId);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  Future<void> _confirmAndDelete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Bạn chắc chắn muốn xóa "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _isDeleting = true; });
    try {
      final success = await api.deleteTask(task.id);
      print('Result deleteTask: $success');
      setState(() { _isDeleting = false; });

      if (success) {
        // lưu vào deleted store trước khi pop
        await DeletedStore.addDeletedId(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
          Navigator.of(context).pop(task.id);
        }
      }
      else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại (server trả false)')));
      }
    } catch (e) {
      setState(() { _isDeleting = false; });
      print('Exception khi delete: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
    }
  }

  // ... phần còn lại giữ nguyên (UI hiển thị)
  Widget _buildChips(Task t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kPinkBox, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _chipItem(Icons.work_outline, t.category),
          const SizedBox(width: 10),
          _chipItem(Icons.history_toggle_off, t.status),
          const SizedBox(width: 10),
          _chipItem(Icons.flag_outlined, t.priority),
        ],
      ),
    );
  }

  Widget _chipItem(IconData icon, String label) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16),
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _subtaskTile(Subtask s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: kLightGrey, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Checkbox(value: s.isCompleted, onChanged: null),
        title: Text(s.title),
      ),
    );
  }

  Widget _attachmentTile(Attachment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [
        BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0,2))
      ]),
      child: Row(children: [
        const Icon(Icons.attach_file),
        const SizedBox(width: 12),
        Expanded(child: Text(a.fileName)),
        IconButton(
          onPressed: () async {
            final uri = Uri.tryParse(a.fileUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.orange),
            onPressed: () async {
              final task = await _futureDetail;
              await _confirmAndDelete(task);
            },
          )
        ],
      ),
      body: FutureBuilder<Task>(
        future: _futureDetail,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final t = snap.data!;
          return Stack(children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (t.desImageURL != null && t.desImageURL!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: t.desImageURL!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(height: 180, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (c, u, e) => Container(height: 180, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image))),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _buildChips(t),
                const SizedBox(height: 12),
                Text('Due: ${_formatDate(t.dueDate)}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Text(t.description),
                const SizedBox(height: 18),
                const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...t.subtasks.map((s) => _subtaskTile(s)).toList(),
                const SizedBox(height: 8),
                const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (t.attachments.isEmpty) const Text('No attachments') else ...t.attachments.map((a) => _attachmentTile(a)).toList(),
                const SizedBox(height: 120),
              ]),
            ),
            if (_isDeleting) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
          ]);
        },
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Colors.orange),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xóa công việc'),
          onPressed: () async {
            final task = await _futureDetail;
            await _confirmAndDelete(task);
          },
        ),
      ),
    );
  }
}
