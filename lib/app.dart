// =============================================================================
// FILE: lib/app.dart
// =============================================================================
// PURPOSE: Root widget of the application
// WHY: Separates app-level configuration from the main() entry point.
//      This widget sets up routing, themes, and BLoC providers.
//
// ═══════════════════════════════════════════════════════════════
// BlocProvider PLACEMENT STRATEGY
// ═══════════════════════════════════════════════════════════════
//
// WHERE should you place BlocProvider?
//
// Option 1: Per Screen (Wrapping individual screens)
//   ✅ Good for: Screen-specific blocs that should close when screen unmounts
//   ❌ Bad for: Shared state that multiple screens need
//
// Option 2: App-level (Wrapping MaterialApp)
//   ✅ Good for: Global state (theme, auth, user preferences)
//   ❌ Bad for: Screen-specific state (lives too long, wastes memory)
//
// For this app:
//   - TodosCubit is app-level because multiple screens need it
//     (HomeScreen reads it, AddEditScreen writes to it)
//   - We place it ABOVE MaterialApp so both screens can access it
//
// ═══════════════════════════════════════════════════════════════
// DEPENDENCY INJECTION IN BLoC
// ═══════════════════════════════════════════════════════════════
//
// The cubit needs a TodoRepository. The repository needs a LocalDatabase.
// We "inject" these dependencies from the outside:
//
//   main.dart creates: LocalDatabase
//   main.dart creates: TodoRepository(localDatabase: db)
//   app.dart creates:  TodosCubit(todoRepository: repo)
//
// This chain ensures:
//   1. Single instances (memory efficient)
//   2. Easy to test (inject mocks)
//   3. Clear dependency graph
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_bloc_guide/data/models/todo_model.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/todo_repository.dart';
import 'logic/todos_cubit.dart';
import 'presentation/screens/add_edit_todo_screen.dart';
import 'presentation/screens/home_screen.dart';

class TodoApp extends StatelessWidget {
  final TodoRepository todoRepository;

  const TodoApp({super.key, required this.todoRepository});

  @override
  Widget build(BuildContext context) {
    // ═══════════════════════════════════════════════════════════════
    // BlocProvider — Provides TodosCubit to the ENTIRE widget tree
    // ═══════════════════════════════════════════════════════════════
    // This is the TOP-LEVEL provider. All screens can access TodosCubit.
    //
    // The 'create' function is called ONCE when the BlocProvider is
    // first inserted into the tree. The cubit lives until the app closes.
    //
    // The '..loadTodos()' is a cascade operator — it creates the cubit
    // AND immediately calls loadTodos(). This ensures data is loaded
    // as soon as the app starts.
    //
    // WHY BlocProvider instead of just creating a cubit variable?
    //   - BlocProvider uses InheritedWidget under the hood
    //   - Any descendant widget can access the cubit via context.read()
    //   - BlocProvider automatically CLOSES the cubit when the widget unmounts
    //     (prevents memory leaks!)
    //   - Without BlocProvider, you'd have to manually manage the cubit lifecycle
    //
    return BlocProvider<TodosCubit>(
      create: (context) =>
          TodosCubit(todoRepository: todoRepository)..loadTodos(),

      // MaterialApp is a descendant, so it CAN access TodosCubit
      child: MaterialApp(
        title: 'Todo BLoC Guide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Follow system theme
        // ───────── Routing ─────────
        // Named routes make navigation clean and consistent
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/add-edit': (context) => AddEditTodoScreen(
                // Extract Todo argument from route settings
                // This is how we pass data between screens
                todo: ModalRoute.of(context)?.settings.arguments as Todo?,
              ),
        },
      ),
    );
  }
}
