// =============================================================================
// FILE: lib/core/database/local_database.dart
// =============================================================================
// PURPOSE: Local database setup using Hive
// WHY: We need persistent storage so todos survive app restarts.
//      Hive is a fast, lightweight, pure-Dart key-value database.
//
// BLOC CONNECTION:
//   Database ←→ Repository ←→ Cubit ←→ UI
//
//   The database is the LOWEST layer. The cubit NEVER talks to the database
//   directly — it goes through the Repository. This separation means:
//   - We can swap Hive for SQLite without touching the cubit
//   - We can test the cubit by mocking the repository
//   - Each layer has a single, clear responsibility
// =============================================================================

import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabase {
  // ───────── Singleton Pattern ─────────
  // WHY: We only want ONE database instance in the entire app.
  // Multiple instances could cause data conflicts.
  static final LocalDatabase _instance = LocalDatabase._internal();

  factory LocalDatabase() => _instance;

  LocalDatabase._internal();

  // ───────── Box Name ─────────
  // In Hive, a "Box" is like a table in SQL databases
  // We store all our todos in a box called 'todos_box'
  static const String _todosBoxName = 'todos_box';

  // ───────── Box Reference ─────────
  // The Box object is our interface to read/write data
  Box<String>? _todosBox;

  // ═══════════════════════════════════════════════════════════════
  // initialize() — MUST be called before any database operations
  // ═══════════════════════════════════════════════════════════════
  // This is typically called in main.dart before runApp()
  //
  // WHY: Hive needs to:
  //   1. Find its storage directory on the device
  //   2. Initialize its internal systems
  //   3. Open the boxes we'll use
  //
  // Without initialization, any database operation will crash!
  //
  Future<void> initialize() async {
    // Step 1: Initialize Hive Flutter bindings
    // This finds the correct directory for database files on each platform
    await Hive.initFlutter();

    // Step 2: Open the todos box
    // If the box doesn't exist, Hive creates it automatically
    // If it exists, Hive loads existing data from disk
    _todosBox = await Hive.openBox<String>(_todosBoxName);
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════

  /// CREATE — Save a new todo as a JSON string
  /// Key = todo.id, Value = JSON string of todo data
  Future<void> saveTodo(String id, String todoJson) async {
    await _todosBox?.put(id, todoJson);
  }

  /// READ ALL — Get all todos from the database
  /// Returns a Map<String, String> where key = id, value = JSON
  Map<String, String> getAllTodos() {
    // _todosBox?.toMap() returns Map<dynamic, dynamic>
    // We cast to Map<String, String> for type safety
    return _todosBox?.toMap().cast<String, String>() ?? {};
  }

  /// READ ONE — Get a single todo by ID
  String? getTodo(String id) {
    return _todosBox?.get(id);
  }

  /// UPDATE — Update an existing todo (same as save, just overwrites)
  Future<void> updateTodo(String id, String todoJson) async {
    await _todosBox?.put(id, todoJson);
  }

  /// DELETE — Remove a todo by ID
  Future<void> deleteTodo(String id) async {
    await _todosBox?.delete(id);
  }

  /// DELETE ALL — Clear the entire box (useful for testing/reset)
  Future<void> clearAll() async {
    await _todosBox?.clear();
  }

  /// Get count of todos in database
  int get count => _todosBox?.length ?? 0;

  // ═══════════════════════════════════════════════════════════════
  // dispose() — Clean up resources when app closes
  // ═══════════════════════════════════════════════════════════════
  Future<void> dispose() async {
    await _todosBox?.close();
  }
}
