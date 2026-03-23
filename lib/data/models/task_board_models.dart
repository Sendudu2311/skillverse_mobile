import 'package:json_annotation/json_annotation.dart';

part 'task_board_models.g.dart';

/// Task priority enum
enum TaskPriority {
  @JsonValue('LOW')
  low,
  @JsonValue('MEDIUM')
  medium,
  @JsonValue('HIGH')
  high,
}

/// Study session status enum
enum SessionStatus {
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('SKIPPED')
  skipped,
}

/// Task Column model for Kanban board
@JsonSerializable()
class TaskColumn {
  final String id;
  final String name;
  final String? color;
  final List<Task> tasks;

  TaskColumn({
    required this.id,
    required this.name,
    this.color,
    this.tasks = const [],
  });

  factory TaskColumn.fromJson(Map<String, dynamic> json) =>
      _$TaskColumnFromJson(json);
  Map<String, dynamic> toJson() => _$TaskColumnToJson(this);

  TaskColumn copyWith({
    String? id,
    String? name,
    String? color,
    List<Task>? tasks,
  }) {
    return TaskColumn(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
    );
  }
}

/// Task model
@JsonSerializable()
class Task {
  final String id;
  final String title;
  final String? description;
  final String? status;
  final TaskPriority priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? deadline;
  final String? columnId;
  final int? userProgress;
  final String? satisfactionLevel;
  final String? userNotes;
  final List<String>? linkedSessionIds;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.priority = TaskPriority.medium,
    this.startDate,
    this.endDate,
    this.deadline,
    this.columnId,
    this.userProgress,
    this.satisfactionLevel,
    this.userNotes,
    this.linkedSessionIds,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadline,
    String? columnId,
    int? userProgress,
    String? satisfactionLevel,
    String? userNotes,
    List<String>? linkedSessionIds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadline: deadline ?? this.deadline,
      columnId: columnId ?? this.columnId,
      userProgress: userProgress ?? this.userProgress,
      satisfactionLevel: satisfactionLevel ?? this.satisfactionLevel,
      userNotes: userNotes ?? this.userNotes,
      linkedSessionIds: linkedSessionIds ?? this.linkedSessionIds,
    );
  }

  /// Whether the task is overdue
  bool get isOverdue {
    if (deadline == null) return false;
    return deadline!.isBefore(DateTime.now()) &&
        status?.toLowerCase() != 'done' &&
        (userProgress == null || userProgress! < 100);
  }

  /// Get priority color
  String get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return '#DC2626'; // Red
      case TaskPriority.medium:
        return '#F59E0B'; // Orange
      case TaskPriority.low:
        return '#10B981'; // Green
    }
  }
}

/// Dashboard Note model
@JsonSerializable()
class DashboardNote {
  final String id;
  final String content;
  final DateTime? createdAt;

  DashboardNote({required this.id, required this.content, this.createdAt});

  factory DashboardNote.fromJson(Map<String, dynamic> json) =>
      _$DashboardNoteFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardNoteToJson(this);
}

/// Study Session model for Timeline
@JsonSerializable()
class StudySession {
  final String id;
  final String? subject;
  final String? topic;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final SessionStatus status;

  StudySession({
    required this.id,
    this.subject,
    this.topic,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.status = SessionStatus.scheduled,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) =>
      _$StudySessionFromJson(json);
  Map<String, dynamic> toJson() => _$StudySessionToJson(this);
}

/// Create Task Request
@JsonSerializable()
class CreateTaskRequest {
  final String title;
  final String? description;
  final String? startDate; // ISO 8601 format: "2026-01-13T09:10"
  final String? endDate;
  final String? deadline;
  final String priority;
  final int? userProgress;
  final String? satisfactionLevel;
  final String? userNotes;
  final String? columnId;
  final List<String>? linkedSessionIds;

  CreateTaskRequest({
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.deadline,
    this.priority = 'MEDIUM',
    this.userProgress = 0,
    this.satisfactionLevel = 'Neutral',
    this.userNotes,
    this.columnId,
    this.linkedSessionIds,
  });

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

/// Update Task Request
@JsonSerializable()
class UpdateTaskRequest {
  final String? title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? deadline;
  final String? priority;
  final int? userProgress;
  final String? satisfactionLevel;
  final String? userNotes;
  final String? columnId;
  final List<String>? linkedSessionIds;

  UpdateTaskRequest({
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.deadline,
    this.priority,
    this.userProgress,
    this.satisfactionLevel,
    this.userNotes,
    this.columnId,
    this.linkedSessionIds,
  });

  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateTaskRequestToJson(this);
}

/// Task Response (maps 1:1 with backend TaskResponse DTO)
@JsonSerializable()
class TaskResponse {
  final String id;
  final String title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? deadline;
  final String priority;
  final String? status;
  final int? userProgress;
  final String? satisfactionLevel;
  final String? userNotes;
  final String? columnId;
  final List<String>? linkedSessionIds;

  TaskResponse({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.deadline,
    required this.priority,
    this.status,
    this.userProgress,
    this.satisfactionLevel,
    this.userNotes,
    this.columnId,
    this.linkedSessionIds,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TaskResponseToJson(this);

  Task toTask() {
    return Task(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: _parsePriority(priority),
      startDate: _parseDate(startDate),
      endDate: _parseDate(endDate),
      deadline: _parseDate(deadline),
      columnId: columnId,
      userProgress: userProgress,
      satisfactionLevel: satisfactionLevel,
      userNotes: userNotes,
      linkedSessionIds: linkedSessionIds,
    );
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  TaskPriority _parsePriority(String value) {
    switch (value.toUpperCase()) {
      case 'HIGH':
        return TaskPriority.high;
      case 'LOW':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

/// Task Column Response
@JsonSerializable()
class TaskColumnResponse {
  final String id;
  final String name;
  final String? color;
  final int? orderIndex;
  final List<TaskResponse> tasks;

  TaskColumnResponse({
    required this.id,
    required this.name,
    this.color,
    this.orderIndex,
    this.tasks = const [],
  });

  factory TaskColumnResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskColumnResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TaskColumnResponseToJson(this);

  TaskColumn toTaskColumn() {
    return TaskColumn(
      id: id,
      name: name,
      color: color,
      tasks: tasks.map((t) => t.toTask()).toList(),
    );
  }
}
