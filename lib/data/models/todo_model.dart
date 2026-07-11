// =============================================================================
// FILE: lib/data/models/todo_model.dart
// =============================================================================
// PURPOSE: The Todo data model — the blueprint for what a "Todo" IS
// WHY:
//   - Defines the STRUCTURE of a todo item (what fields it has)
//   - Provides SERIALIZATION (converting to/from JSON for database storage)
//   - Uses Equatable for VALUE COMPARISON (critical for BLoC!)
//
// ═══════════════════════════════════════════════════════════════
// WHY Equatable is CRITICAL for BLoC States
// ═══════════════════════════════════════════════════════════════
//
// By default, Dart compares objects by REFERENCE (memory address):
//   final a = Todo(id: '1', title: 'Buy milk');
//   final b = Todo(id: '1', title: 'Buy milk');
//   a == b  →  FALSE  (different objects in memory!)
//
// With Equatable, objects are compared by VALUE (their properties):
//   a == b  →  TRUE  (same id and title!)
//
// This matters because:
//   1. BlocBuilder checks: "is the new state different from the old state?"
//   2. Without Equatable: Two states with same data are "different" → excess rebuilds
//   3. With Equatable: Two states with same data are "equal" → no rebuild (efficient!)
//   4. When a todo's title changes: Props are different → state changed → rebuild (correct!)
//
// ═══════════════════════════════════════════════════════════════
// The Model vs State Distinction
// ═══════════════════════════════════════════════════════════════
//
// Model:  Todo          → Represents a single todo item (DATA layer)
// State:  TodosLoaded   → Represents the UI state containing todos (LOGIC layer)
//
// Models are the BUILDING BLOCKS of states. A state might contain a List<Todo>.
// The model doesn't know about BLoC — it's pure data.
// =============================================================================

import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════
/// Priority Enum — Represents the urgency of a todo
/// ═══════════════════════════════════════════════════════════════
/// Enums are perfect for fixed sets of options.
/// They're type-safe — you can't accidentally use "Urgent" instead of "high"
///
enum TodoPriority {
  high, // Red — needs attention NOW
  medium, // Orange — important but not urgent
  low; // Green — can wait

  /// Get display name for each priority
  String get displayName {
    switch (this) {
      case TodoPriority.high:
        return 'High';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.low:
        return 'Low';
    }
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Category Enum — Groups todos by type
/// ═══════════════════════════════════════════════════════════════
enum TodoCategory {
  work,
  personal,
  shopping,
  health,
  education;

  String get displayName {
    switch (this) {
      case TodoCategory.work:
        return 'Work';
      case TodoCategory.personal:
        return 'Personal';
      case TodoCategory.shopping:
        return 'Shopping';
      case TodoCategory.health:
        return 'Health';
      case TodoCategory.education:
        return 'Education';
    }
  }

  /// Icon for each category — useful in the UI
  String get icon {
    switch (this) {
      case TodoCategory.work:
        return '💼';
      case TodoCategory.personal:
        return '👤';
      case TodoCategory.shopping:
        return '🛒';
      case TodoCategory.health:
        return '❤️';
      case TodoCategory.education:
        return '📚';
    }
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Todo Model — The core data structure
/// ═══════════════════════════════════════════════════════════════
///
/// Extends Equatable so we can compare todos by VALUE, not reference.
/// All fields are final — the model is IMMUTABLE.
/// To "change" a todo, you create a NEW instance with copyWith().
///
/// WHY IMMUTABLE?
///   1. BLoC states must be immutable — you can't modify an existing state
///   2. Immutable objects are thread-safe (important for async operations)
///   3. Easier to reason about: "who changed this?" — nobody, it's new!
///   4. Flutter's diff algorithm works better with immutable objects
///
class Todo extends Equatable {
  final String id; // Unique identifier (UUID)
  final String title; // What to do
  final String description; // More details (optional)
  final bool isCompleted; // Done or not?
  final TodoPriority priority; // How urgent?
  final TodoCategory category; // What type?
  final DateTime createdAt; // When was it created?
  final DateTime? dueDate; // When should it be done? (optional)
  final DateTime? completedAt; // When was it marked done? (optional)

  const Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.personal,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // Equatable — Define which properties determine "equality"
  // ═══════════════════════════════════════════════════════════════
  // Two Todos are "equal" if ALL these properties match.
  // BlocBuilder uses this to decide: "Should I rebuild the widget?"
  //
  // If you forget to include a property here:
  //   - That property changes but the widget doesn't rebuild (BUG!)
  // So include ALL properties that affect the UI.
  //
  @override
  List<Object?> get props => [
    id,
    title,
    description,
    isCompleted,
    priority,
    category,
    createdAt,
    dueDate,
    completedAt,
  ];

  // ═══════════════════════════════════════════════════════════════
  // copyWith() — Create a new Todo with some properties changed
  // ═══════════════════════════════════════════════════════════════
  // This is the IMMUTABLE way to "modify" an object.
  // Instead of:  todo.isCompleted = true;  ← MUTABLE (bad for BLoC)
  // We do:       final updated = todo.copyWith(isCompleted: true);  ← NEW object
  //
  // HOW IT WORKS:
  //   1. Takes named parameters for each field (all optional)
  //   2. Uses the existing value if parameter not provided
  //   3. Creates a new Todo with the updated values
  //
  // The ?? operator means: "use the provided value, or fall back to current"
  //
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TodoPriority? priority,
    TodoCategory? category,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    bool clearDueDate = false, // Special flag to set dueDate to null
    bool clearCompletedAt = false, // Special flag to set completedAt to null
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // JSON Serialization — Convert to/from Map for database storage
  // ═══════════════════════════════════════════════════════════════
  // Hive stores key-value pairs. We convert our Todo to a JSON map,
  // then to a JSON string, and store that string in Hive.
  //
  // toJson() → Map<String, dynamic> → jsonEncode() → String → Hive
  // Hive → String → jsonDecode() → Map<String, dynamic> → fromJson() → Todo
  //

  /// Convert Todo to a Map (for JSON encoding)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.index, // Store enum as int
      'category': category.index, // Store enum as int
      'createdAt': createdAt.toIso8601String(), // Store DateTime as String
      'dueDate': dueDate?.toIso8601String(), // Nullable DateTime
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Create Todo from a Map (after JSON decoding)
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      // Convert int back to enum using values list
      priority: TodoPriority.values[json['priority'] as int? ?? 1],
      category: TodoCategory.values[json['category'] as int? ?? 1],
      // Parse ISO8601 string back to DateTime
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// A helpful string representation for debugging
  @override
  String toString() {
    return 'Todo(id: $id, title: $title, completed: $isCompleted, '
        'priority: ${priority.displayName}, category: ${category.displayName})';
  }
}
