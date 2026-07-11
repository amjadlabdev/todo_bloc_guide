// =============================================================================
// FILE: lib/main.dart
// =============================================================================
// PURPOSE: Entry point of the Flutter application
// WHY: This is where execution begins. We initialize services and run the app.
//
// ═══════════════════════════════════════════════════════════════
// STARTUP SEQUENCE — What happens before the UI appears
// ═══════════════════════════════════════════════════════════════
//
// 1. WidgetsFlutterBinding.ensureInitialized()
//    → Initializes Flutter's binding to the native platform
//    → Required BEFORE any Flutter plugins (like Hive) can be used
//    → Without this: Crash! "ServicesBinding.defaultBinaryMessenger was accessed
//      before the binding was initialized"
//
// 2. LocalDatabase().initialize()
//    → Initializes Hive (finds storage directory, opens database boxes)
//    → Must happen BEFORE any database operations
//    → We "await" this because the app can't work without the database
//
// 3. Create Repository
//    → Repository wraps the database
//    → We inject the database into the repository
//
// 4. runApp(TodoApp())
//    → Creates the root widget and starts the rendering pipeline
//    → From this point, Flutter takes over and builds the widget tree
//    → BlocProvider in TodoApp creates the TodosCubit
//
// ═══════════════════════════════════════════════════════════════
// BLOC OBSERVER (Optional but powerful)
// ═══════════════════════════════════════════════════════════════
//
// BLoC has a built-in observability system called BlocObserver.
// It lets you monitor ALL state changes across ALL cubits/blocs.
// This is INCREDIBLY useful for debugging!
//
// Usage:
//   Bloc.observer = AppBlocObserver();
//
// Now every time any cubit emits a state, you'll see it in the console.
// This helps you answer: "Why did the UI update?" → Check the logs!
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/local_database.dart';
import 'data/repositories/todo_repository.dart';
import 'app.dart';

// ═══════════════════════════════════════════════════════════════
// AppBlocObserver — Monitors all BLoC/Cubit state changes
// ═══════════════════════════════════════════════════════════════
// This is like having a security camera in every cubit.
// You can see:
//   - When a cubit is created (onCreate)
//   - When a state change happens (onChange) — MOST USEFUL!
//   - When an error occurs (onError)
//   - When a cubit is closed (onClose)
//
// In production, you might send these logs to a crash reporting service
// like Firebase Crashlytics or Sentry.
//
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('🔵 BLoC CREATED: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // ═══════════════════════════════════════════════════════════════
    // THIS IS THE MOST IMPORTANT LOG!
    // It shows: Previous State → Current State
    // ═══════════════════════════════════════════════════════════════
    // Example output:
    //   🔄 BLoC CHANGE in TodosCubit:
    //     FROM: TodosInitial
    //     TO:   TodosLoading
    //
    //   🔄 BLoC CHANGE in TodosCubit:
    //     FROM: TodosLoading
    //     TO:   TodosLoaded(todos: [Todo(...), Todo(...)])
    //
    // This tells you EXACTLY what caused the UI to rebuild!
    //
    debugPrint('🔄 BLoC CHANGE in ${bloc.runtimeType}:');
    debugPrint('   FROM: ${change.currentState}');
    debugPrint('   TO:   ${change.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('❌ BLoC ERROR in ${bloc.runtimeType}: $error');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    debugPrint('🔴 BLoC CLOSED: ${bloc.runtimeType}');
  }
}

// ═══════════════════════════════════════════════════════════════
// main() — The entry point
// ═══════════════════════════════════════════════════════════════
void main() async {
  // Step 1: Ensure Flutter bindings are initialized
  // CRITICAL: Must be called BEFORE any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Set up BLoC Observer for debugging
  // This lets us see all state changes in the console
  Bloc.observer = AppBlocObserver();

  // Step 3: Initialize the local database
  // This opens the Hive database and prepares it for use
  final localDatabase = LocalDatabase();
  await localDatabase.initialize();

  // Step 4: Create the repository with the database dependency
  // Repository = middleman between cubit and database
  final todoRepository = TodoRepository(localDatabase: localDatabase);

  // Step 5: Run the app!
  // We pass the repository to the root widget via constructor injection
  // This is called "constructor injection" — the cleanest form of DI
  runApp(TodoApp(todoRepository: todoRepository));
}
