// models/task.dart
class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final DateTime? dueDate;
  final String? desImageURL;
  final List<Subtask> subtasks;
  final List<Attachment> attachments;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.desImageURL,
    required this.subtasks,
    required this.attachments,
  });

  factory Task.fromJson(Map<String, dynamic> j) {
    DateTime? parsedDue;
    if (j['dueDate'] != null) {
      try {
        parsedDue = DateTime.parse(j['dueDate']);
      } catch (e) {
        parsedDue = null;
      }
    }
    List<Subtask> subs = [];
    if (j['subtasks'] is List) {
      subs = (j['subtasks'] as List)
          .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    List<Attachment> atts = [];
    if (j['attachments'] is List) {
      atts = (j['attachments'] as List)
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return Task(
      id: j['id'] as int,
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      status: j['status'] ?? '',
      priority: j['priority'] ?? '',
      category: j['category'] ?? '',
      dueDate: parsedDue,
      desImageURL: j['desImageURL'],
      subtasks: subs,
      attachments: atts,
    );
  }
}

class Subtask {
  final int id;
  final String title;
  final bool isCompleted;
  Subtask({required this.id, required this.title, required this.isCompleted});
  factory Subtask.fromJson(Map<String, dynamic> j) {
    return Subtask(
      id: j['id'] as int,
      title: j['title'] ?? '',
      isCompleted: j['isCompleted'] ?? false,
    );
  }
}

class Attachment {
  final int id;
  final String fileName;
  final String fileUrl;
  Attachment({required this.id, required this.fileName, required this.fileUrl});
  factory Attachment.fromJson(Map<String, dynamic> j) {
    return Attachment(
      id: j['id'] as int,
      fileName: j['fileName'] ?? '',
      fileUrl: j['fileUrl'] ?? '',
    );
  }
}
