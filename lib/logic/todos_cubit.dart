// =============================================================================
// FILE: lib/logic/todos_cubit.dart
// =============================================================================
// PURPOSE: The TodosCubit — THE BRAIN of the todos feature
// WHY: This is where ALL business logic lives. No UI code, no database code.
//      Just pure logic: "When user does X, what should happen to the state?"
//
// ═══════════════════════════════════════════════════════════════
// WHAT IS A CUBIT? — The Simplest Form of BLoC
// ═══════════════════════════════════════════════════════════════
//
// A Cubit is a class that:
//   1. Holds a CURRENT STATE (accessible via .state property)
//   2. Exposes METHODS that can change the state
//   3. Uses emit() to broadcast new states to listening widgets
//   4. Extends Cubit<StateType> from the flutter_bloc package
//
// Think of it like a light switch:
//   - The switch has a current state: ON or OFF
//   - You call a method: flipSwitch()
//   - The switch emits the new state: ON → OFF
//   - Anyone watching the switch (widgets) sees the change
//
// ═══════════════════════════════════════════════════════════════
// CUBIT vs BLoC — What's the difference?
// ═══════════════════════════════════════════════════════════════
//
// Cubit:
//   class CounterCubit extends Cubit<int> {
//     CounterCubit() : super(0);
//     void increment() => emit(state + 1);  ← Method triggers emit
//   }
//   // Usage: cubit.increment();
//
// BLoC:
//   class CounterBloc extends Bloc<CounterEvent, int> {
//     CounterBloc() : super(0) {
//       on<Increment>((event, emit) => emit(state + 1));  ← Event triggers emit
//     }
//   }
//   // Usage: bloc.add(Increment());
//
// Key differences:
//   - Cubit uses METHODS, BLoC uses EVENTS
//   - Cubit has less boilerplate
//   - BLoC supports event transformation (debounce, throttle, etc.)
//   - BLoC provides better traceability (every event is logged)
//   - Under the hood, Cubit IS a BLoC! It just auto-creates events for each method
//
// ═══════════════════════════════════════════════════════════════
// RULES FOR WRITING A GOOD CUBIT
// ═══════════════════════════════════════════════════════════════
//
// ✅ DO:
//   - Keep one responsibility per cubit (Single Responsibility Principle)
//   - Make every method name describe WHAT the user action is (addTodo, not setData)
//   - Always emit a new state after every meaningful action
//   - Handle errors gracefully (emit error state, don't let exceptions escape)
//   - Use the repository for ALL data operations
//   - Document what each method does and when it's called
//
// ❌ DON'T:
//   - Never import Flutter widgets in a cubit
//   - Never access BuildContext in a cubit
//   - Never do UI work (navigation, snackbars) in a cubit
//   - Never directly access the database — use the repository
//   - Never modify the state directly — always emit() a new one
//
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../data/models/todo_model.dart';
import '../data/repositories/todo_repository.dart';
import 'todos_state.dart';

class TodosCubit extends Cubit<TodosState> {
  // ───────── Dependencies ─────────
  // The cubit depends on the repository, NOT the database.
  // This is Dependency Injection — we receive the repository from outside.
  //
  // WHY: So we can MOCK the repository in tests!
  // In production: TodosCubit(realRepository)
  // In tests:      TodosCubit(mockRepository)
  //
  final TodoRepository _todoRepository;

  // UUID generator for creating unique todo IDs
  final Uuid _uuid = const Uuid();

  // ───────── Constructor ─────────
  // super(TodosInitial()) sets the INITIAL STATE
  // This is the state before any action is taken
  //
  // WHY TodosInitial and not TodosLoading?
  //   - Initial = "just born, haven't done anything yet"
  //   - Loading = "actively fetching data"
  //   - The cubit doesn't start loading until loadTodos() is called
  //
  TodosCubit({required TodoRepository todoRepository})
    : _todoRepository = todoRepository,
      super(const TodosInitial());

  // ═══════════════════════════════════════════════════════════════
  // LOAD ALL TODOS
  // ═══════════════════════════════════════════════════════════════
  // Called when: App starts, user pulls to refresh, after any change
  //
  // Flow:
  //   1. Emit Loading state → UI shows spinner
  //   2. Call repository → Get data from database
  //   3. Emit Loaded state with data → UI shows todo list
  //   4. If error → Emit Error state → UI shows error message
  //
  // WHY async/await?
  //   Database operations take time. We don't want to freeze the UI.
  //   async/await lets Dart do other work while waiting for the database.
  //
  Future<void> loadTodos() async {
    // Step 1: Tell UI we're loading
    emit(const TodosLoading());

    try {
      // Step 2: Get data from repository (which gets it from database)
      final todos = await _todoRepository.getAllTodos();

      // Step 3: Tell UI we have data!
      // Loaded state includes the todos AND default filter values
      emit(
        TodosLoaded(
          todos: todos,
          searchQuery: '',
          selectedCategory: null,
          selectedPriority: null,
        ),
      );
    } catch (e) {
      // Step 4: Something went wrong — tell UI about the error
      // We don't throw the error — we emit an error state.
      // WHY: If we throw, the error propagates up and might crash the app.
      //       Emitting an error state lets the UI handle it gracefully.
      emit(TodosError(e.toString()));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD A NEW TODO
  // ═══════════════════════════════════════════════════════════════
  // Called when: User fills in the add form and taps "Add"
  //
  // IMPORTANT: After adding, we RELOAD all todos from the database.
  // WHY not just add to the existing list?
  //   1. Database is the source of truth — we want to be in sync
  //   2. The database might have triggers or defaults we're not aware of
  //   3. It's simpler and more reliable than manually managing the list
  //   4. For a small app like this, the performance difference is negligible
  //
  // For LARGE apps with many items, you might optimize by adding
  // to the local list without a full reload. This is called
  // "optimistic updates" — we'll see that in deleteTodo().
  //
  Future<void> addTodo({
    required String title,
    String description = '',
    TodoPriority priority = TodoPriority.medium,
    TodoCategory category = TodoCategory.personal,
    DateTime? dueDate,
  }) async {
    try {
      // Step 1: Create a new Todo model
      final todo = Todo(
        id: _uuid.v4(), // Generate unique ID
        title: title,
        description: description,
        priority: priority,
        category: category,
        createdAt: DateTime.now(), // Set creation time
        dueDate: dueDate,
      );

      // Step 2: Save to database via repository
      await _todoRepository.addTodo(todo);

      // Step 3: Reload all todos to get the updated list
      await loadTodos();

      // Step 4: Emit an action state for one-time feedback
      // This triggers BlocListener to show a SnackBar
      // After the listener handles it, we'll be back in TodosLoaded
      // We re-emit the loaded state to maintain UI consistency
      if (state is TodosLoaded) {
        emit(TodoAdded(todo));
        // Re-emit the loaded state so the UI has the latest data
        emit(state);
      }
    } catch (e) {
      emit(TodosError('Failed to add todo: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATE AN EXISTING TODO
  // ═══════════════════════════════════════════════════════════════
  // Called when: User edits a todo and taps "Save"
  //
  Future<void> updateTodo({
    required String id,
    required String title,
    String description = '',
    TodoPriority priority = TodoPriority.medium,
    TodoCategory category = TodoCategory.personal,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    try {
      // Get current state to find the existing todo
      if (state is! TodosLoaded) return;
      final currentState = state as TodosLoaded;

      // Find the existing todo by ID
      final existingTodo = currentState.todos.firstWhere(
        (todo) => todo.id == id,
      );

      // Create updated todo using copyWith (immutable update!)
      final updatedTodo = existingTodo.copyWith(
        title: title,
        description: description,
        priority: priority,
        category: category,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
      );

      // Save to database
      await _todoRepository.updateTodo(updatedTodo);

      // Reload and emit feedback
      await loadTodos();
      if (state is TodosLoaded) {
        emit(TodoUpdated(updatedTodo));
        emit(state);
      }
    } catch (e) {
      emit(TodosError('Failed to update todo: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE A TODO
  // ═══════════════════════════════════════════════════════════════
  // Called when: User swipes to delete or taps delete button
  //
  // This uses OPTIMISTIC UPDATES:
  //   1. Remove the todo from the UI state FIRST (optimistic)
  //   2. Then try to delete from database
  //   3. If database fails, put the todo back (rollback)
  //
  // WHY optimistic? The user sees the deletion immediately — faster UX.
  // If the database fails (rare), we undo the change and show an error.
  //
  Future<void> deleteTodo(String id) async {
    // Save the current state for potential rollback
    final previousState = state;

    try {
      if (state is TodosLoaded) {
        final currentState = state as TodosLoaded;

        // Step 1: Find the todo being deleted (for undo feature)
        final deletedTodo = currentState.todos.firstWhere(
          (todo) => todo.id == id,
        );

        // Step 2: Optimistically remove from state
        // Create new list WITHOUT the deleted todo
        final updatedTodos = currentState.todos
            .where((todo) => todo.id != id)
            .toList();

        // Emit the updated state immediately (UI updates before DB confirms)
        emit(currentState.copyWith(todos: updatedTodos));

        // Step 3: Actually delete from database
        await _todoRepository.deleteTodo(id);

        // Step 4: Emit action state for SnackBar with undo option
        emit(TodoDeleted(deletedTodo));

        // Re-emit the loaded state to maintain consistency
        // We need to re-fetch because the database is the source of truth
        emit(currentState.copyWith(todos: updatedTodos));
      }
    } catch (e) {
      // Step 5: ROLLBACK — restore previous state if delete failed
      emit(previousState);
      emit(TodosError('Failed to delete todo: $e'));
      // Re-emit previous state after error
      if (previousState is TodosLoaded) {
        emit(previousState);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UNDO DELETE — Restore a deleted todo
  // ═══════════════════════════════════════════════════════════════
  // Called when: User taps "Undo" on the delete SnackBar
  //
  Future<void> undoDelete(Todo todo) async {
    try {
      // Re-add the todo to the database
      await _todoRepository.addTodo(todo);
      // Reload to get the restored list
      await loadTodos();
    } catch (e) {
      emit(TodosError('Failed to restore todo: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE COMPLETION — Mark todo as done/undone
  // ═══════════════════════════════════════════════════════════════
  // Called when: User taps the checkbox on a todo
  //
  Future<void> toggleCompletion(String id) async {
    try {
      if (state is TodosLoaded) {
        final currentState = state as TodosLoaded;
        final todo = currentState.todos.firstWhere((t) => t.id == id);

        // Toggle in database
        await _todoRepository.toggleCompletion(todo);

        // Optimistically update the state
        final updatedTodos = currentState.todos.map((t) {
          if (t.id == id) {
            return t.copyWith(
              isCompleted: !t.isCompleted,
              completedAt: !t.isCompleted ? DateTime.now() : null,
              clearCompletedAt: t.isCompleted,
            );
          }
          return t;
        }).toList();

        emit(currentState.copyWith(todos: updatedTodos));
        emit(TodoCompletionToggled(todo));
        emit(currentState.copyWith(todos: updatedTodos));
      }
    } catch (e) {
      emit(TodosError('Failed to toggle completion: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH — Filter todos by search query
  // ═══════════════════════════════════════════════════════════════
  // Called when: User types in the search bar
  //
  // NOTE: We DON'T reload from the database here.
  // We just update the searchQuery in the state, and the computed
  // property filteredTodos in TodosLoaded handles the filtering.
  // This is MUCH faster than a database query for every keystroke!
  //
  // This is a great example of the Cubit managing UI logic:
  //   - Database: Stores ALL todos
  //   - State: Holds ALL todos + current search query
  //   - Computed property: Filters based on query
  //   - UI: Shows only filtered results
  //
  void searchTodos(String query) {
    if (state is TodosLoaded) {
      final currentState = state as TodosLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR SEARCH
  // ═══════════════════════════════════════════════════════════════
  void clearSearch() {
    if (state is TodosLoaded) {
      final currentState = state as TodosLoaded;
      emit(currentState.copyWith(searchQuery: ''));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER BY CATEGORY
  // ═══════════════════════════════════════════════════════════════
  // Called when: User taps a category chip
  // If the same category is tapped again, clear the filter (toggle off)
  //
  void filterByCategory(TodoCategory? category) {
    if (state is TodosLoaded) {
      final currentState = state as TodosLoaded;
      // If same category selected, clear filter (toggle behavior)
      if (currentState.selectedCategory == category) {
        emit(currentState.copyWith(clearCategory: true));
      } else {
        emit(currentState.copyWith(selectedCategory: category));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER BY PRIORITY
  // ═══════════════════════════════════════════════════════════════
  void filterByPriority(TodoPriority? priority) {
    if (state is TodosLoaded) {
      final currentState = state as TodosLoaded;
      if (currentState.selectedPriority == priority) {
        emit(currentState.copyWith(clearPriority: true));
      } else {
        emit(currentState.copyWith(selectedPriority: priority));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR ALL FILTERS
  // ═══════════════════════════════════════════════════════════════
  void clearFilters() {
    if (state is TodosLoaded) {
      final currentState = state as TodosLoaded;
      emit(
        currentState.copyWith(
          searchQuery: '',
          clearCategory: true,
          clearPriority: true,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR ALL TODOS (danger zone!)
  // ═══════════════════════════════════════════════════════════════
  Future<void> clearAllTodos() async {
    try {
      await _todoRepository.clearAllTodos();
      emit(const TodosLoaded(todos: []));
    } catch (e) {
      emit(TodosError('Failed to clear todos: $e'));
    }
  }
}
