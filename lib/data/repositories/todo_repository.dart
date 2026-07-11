// =============================================================================
// FILE: lib/data/repositories/todo_repository.dart
// =============================================================================
// PURPOSE: The Repository — the MIDDLEMAN between Cubit and Database
// WHY:
//   - Cubit should NOT know about Hive, SQLite, or any data source
//   - Repository abstracts the data layer behind a clean interface
//   - We can swap Hive for SQLite/API without touching the cubit
//   - We can mock the repository for unit testing the cubit
//
// ═══════════════════════════════════════════════════════════════
// THE REPOSITORY PATTERN IN BLoC ARCHITECTURE
// ═══════════════════════════════════════════════════════════════
//
//   UI Widget
//      │
//      │ calls method
//      ▼
//   TodosCubit ◄──── THIS IS WHERE BUSINESS LOGIC LIVES
//      │
//      │ calls repository method
//      ▼
//   TodoRepository ◄──── THIS FILE (data coordination)
//      │
//      │ calls database method
//      ▼
//   LocalDatabase ◄──── raw data operations
//
// The Repository's job:
//   1. Receive requests from the Cubit
//   2. Convert between Models (what Cubit understands) and raw data (what DB stores)
//   3. Coordinate between different data sources (if we had API + local)
//   4. Handle data-level errors and convert them to user-friendly messages
//   5. Return Models back to the Cubit
//
// =============================================================================

import 'dart:convert';
import '../../core/database/local_database.dart';
import '../models/todo_model.dart';

class TodoRepository {
  // ───────── Dependencies ─────────
  // The repository depends on the database, NOT the other way around.
  // This is called "Dependency Injection" — we inject the database
  // through the constructor.
  //
  // WHY INJECT instead of creating inside?
  //   1. Testability: We can inject a mock database for testing
  //   2. Flexibility: We can inject different database implementations
  //   3. Separation: Repository doesn't need to know HOW to create a database
  //
  final LocalDatabase _localDatabase;

  // Constructor with required dependency
  TodoRepository({required LocalDatabase localDatabase})
    : _localDatabase = localDatabase;

  // ═══════════════════════════════════════════════════════════════
  // GET ALL TODOS
  // ═══════════════════════════════════════════════════════════════
  // Flow: Database → Raw Map → Parse JSON → List of Todo Models
  //
  // This method shows the repository's main job:
  //   1. Get raw data from database (Map<String, String>)
  //   2. Convert each JSON string to a Todo model
  //   3. Sort by creation date (newest first)
  //   4. Return clean List<Todo> to the cubit
  //
  Future<List<Todo>> getAllTodos() async {
    try {
      // Step 1: Get all raw data from database
      final todosMap = _localDatabase.getAllTodos();

      // Step 2: Convert each entry to a Todo model
      final todos = todosMap.entries.map((entry) {
        // entry.value is a JSON string like: '{"id":"1","title":"Buy milk",...}'
        // jsonDecode converts it to a Map<String, dynamic>
        final json = jsonDecode(entry.value) as Map<String, dynamic>;
        // fromJson converts the Map to a Todo object
        return Todo.fromJson(json);
      }).toList();

      // Step 3: Sort by creation date (newest first)
      todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return todos;
    } catch (e) {
      // The repository catches data-layer errors and re-throws with context
      // The cubit will catch this and emit an error state
      throw Exception('Failed to load todos: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD TODO
  // ═══════════════════════════════════════════════════════════════
  // Flow: Todo Model → JSON String → Database Save
  //
  Future<void> addTodo(Todo todo) async {
    try {
      // Convert model to JSON string for database storage
      final todoJson = jsonEncode(todo.toJson());
      await _localDatabase.saveTodo(todo.id, todoJson);
    } catch (e) {
      throw Exception('Failed to add todo: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATE TODO
  // ═══════════════════════════════════════════════════════════════
  Future<void> updateTodo(Todo todo) async {
    try {
      final todoJson = jsonEncode(todo.toJson());
      await _localDatabase.updateTodo(todo.id, todoJson);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE TODO
  // ═══════════════════════════════════════════════════════════════
  Future<void> deleteTodo(String id) async {
    try {
      await _localDatabase.deleteTodo(id);
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE COMPLETION
  // ═══════════════════════════════════════════════════════════════
  // This is a DOMAIN operation — the repository understands the
  // business meaning of "toggling completion", not just "updating a record"
  //
  Future<void> toggleCompletion(Todo todo) async {
    try {
      // Use copyWith to create a new todo with isCompleted toggled
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        // If completing, set completedAt; if uncompleting, clear it
        completedAt: !todo.isCompleted ? DateTime.now() : null,
        clearCompletedAt: todo.isCompleted, // Clear if was completed
      );
      final todoJson = jsonEncode(updatedTodo.toJson());
      await _localDatabase.updateTodo(updatedTodo.id, todoJson);
    } catch (e) {
      throw Exception('Failed to toggle completion: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR ALL TODOS
  // ═══════════════════════════════════════════════════════════════
  Future<void> clearAllTodos() async {
    try {
      await _localDatabase.clearAll();
    } catch (e) {
      throw Exception('Failed to clear todos: $e');
    }
  }
}
