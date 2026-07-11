// =============================================================================
// FILE: lib/logic/todos_state.dart
// =============================================================================
// PURPOSE: Define ALL possible states for the Todos feature
// WHY: States are the "output" of a Cubit. They tell the UI what to render.
//
// ═══════════════════════════════════════════════════════════════
// THE STATE PATTERN IN BLoC — A DEEP DIVE
// ═══════════════════════════════════════════════════════════════
//
// BLoC uses a "sealed class hierarchy" for states. This means:
//   1. A base class (TodosState) defines the common type
//   2. Subclasses represent each distinct state the app can be in
//   3. The UI uses "is" checks to determine what to render
//   4. The compiler can warn you if you miss a state case
//
// Think of it like a traffic light:
//   - Red light    → TodosLoading (wait!)
//   - Green light  → TodosLoaded  (go! show the data)
//   - Yellow light → TodosError   (caution! something's wrong)
//
// KEY RULES FOR BLoC STATES:
//   ✅ ALWAYS extend Equatable
//   ✅ ALWAYS make states IMMUTABLE (final fields only)
//   ✅ ALWAYS include all UI-relevant fields in props
//   ✅ Name states clearly: "What is the app doing right now?"
//   ❌ NEVER put methods in state classes
//   ❌ NEVER mutate state fields
//   ❌ NEVER put UI widgets in states
//
// ═══════════════════════════════════════════════════════════════
// WHY NOT JUST USE A SINGLE STATE CLASS WITH AN ENUM?
// ═══════════════════════════════════════════════════════════════
//
// You COULD do this:
//   class TodosState {
//     final Status status; // loading, loaded, error
//     final List<Todo> todos;
//     final String? errorMessage;
//   }
//
// But separate classes are BETTER because:
//   1. Type safety: The compiler ensures you handle every state
//   2. Only relevant data: TodosLoading doesn't need a List<Todo>
//   3. No nullable chaos: loaded.todos is always available in TodosLoaded
//   4. Exhaustive switching: Dart's switch can check all subclasses
//
// Compare:
//   // Single class — what if todos is null? Always checking...
//   if (state.status == Status.loaded && state.todos != null) { ... }
//
//   // Separate classes — compiler guarantees todos exists!
//   if (state is TodosLoaded) { print(state.todos); }  // No null check!
//
// =============================================================================

import 'package:equatable/equatable.dart';
import '../data/models/todo_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// BASE STATE CLASS
/// ═══════════════════════════════════════════════════════════════
/// All todo states extend this class. This allows the UI to handle
/// any state with a single type: TodosState
///
/// We use an ABSTRACT class because you should never create a raw TodosState.
/// You always use one of the specific subclasses.
///
abstract class TodosState extends Equatable {
  const TodosState();

  // Every subclass MUST override props for Equatable comparison
  @override
  List<Object?> get props => [];
}

/// ═══════════════════════════════════════════════════════════════
/// INITIAL STATE — App just started, no action taken yet
/// ═══════════════════════════════════════════════════════════════
/// This is the state BEFORE any data loading begins.
/// The cubit is created with this state: TodosCubit() : super(TodosInitial())
///
/// UI behavior: Might show a loading indicator, or immediately trigger loadTodos()
///
class TodosInitial extends TodosState {
  const TodosInitial();

  @override
  List<Object?> get props => []; // No data to compare — singleton state
}

/// ═══════════════════════════════════════════════════════════════
/// LOADING STATE — Data is being fetched
/// ═══════════════════════════════════════════════════════════════
/// Shown while the cubit is waiting for data from the repository.
/// Could be initial load or a refresh.
///
/// UI behavior: Show loading spinner/shimmer
///
class TodosLoading extends TodosState {
  const TodosLoading();

  @override
  List<Object?> get props => [];
}

/// ═══════════════════════════════════════════════════════════════
/// LOADED STATE — Data successfully loaded
/// ═══════════════════════════════════════════════════════════════
/// The "happy path" state. Contains the actual todo data.
///
/// IMPORTANT: We include ALL data that affects the UI in props:
///   - todos: The main list
///   - searchQuery: Current search filter (affects which todos show)
///   - selectedCategory: Current category filter
///   - selectedPriority: Current priority filter
///
/// If searchQuery changes but todos don't, we STILL want the UI to rebuild
/// because different todos will be shown. So searchQuery MUST be in props!
///
/// UI behavior: Show the filtered/sorted todo list
///
class TodosLoaded extends TodosState {
  final List<Todo> todos; // All todos from database
  final String searchQuery; // Current search term
  final TodoCategory? selectedCategory; // Current category filter (null = all)
  final TodoPriority? selectedPriority; // Current priority filter (null = all)

  const TodosLoaded({
    required this.todos,
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedPriority,
  });

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES — Filtered/derived data
  // ═══════════════════════════════════════════════════════════════
  // These are NOT stored separately — they're COMPUTED from the base data.
  // WHY: Storing filtered lists separately creates sync bugs.
  // If you update todos but forget to update filteredTodos = bug!
  // Computing them ensures they're always in sync.
  //

  /// Returns todos filtered by search query, category, and priority
  /// This is what the UI actually displays
  List<Todo> get filteredTodos {
    List<Todo> result = todos;

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      result = result.where((todo) {
        final query = searchQuery.toLowerCase();
        return todo.title.toLowerCase().contains(query) ||
            todo.description.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by category
    if (selectedCategory != null) {
      result = result
          .where((todo) => todo.category == selectedCategory)
          .toList();
    }

    // Filter by priority
    if (selectedPriority != null) {
      result = result
          .where((todo) => todo.priority == selectedPriority)
          .toList();
    }

    return result;
  }

  /// Count of completed todos
  int get completedCount => todos.where((t) => t.isCompleted).length;

  /// Count of incomplete todos
  int get incompleteCount => todos.where((t) => !t.isCompleted).length;

  /// Count of overdue todos
  int get overdueCount => todos.where((t) {
    if (t.dueDate == null || t.isCompleted) return false;
    return t.dueDate!.isBefore(DateTime.now());
  }).length;

  // ═══════════════════════════════════════════════════════════════
  // Equatable props — INCLUDE EVERYTHING that affects UI rendering
  // ═══════════════════════════════════════════════════════════════
  @override
  List<Object?> get props => [
    todos,
    searchQuery,
    selectedCategory,
    selectedPriority,
  ];

  // ═══════════════════════════════════════════════════════════════
  // copyWith — Create a new state with some properties changed
  // ═══════════════════════════════════════════════════════════════
  // This is how the cubit creates new states. Remember:
  //   States are IMMUTABLE — we can't modify them
  //   We create NEW states with the changes
  //
  // Example in cubit:
  //   emit(state.copyWith(searchQuery: 'buy'));
  //   This creates a new TodosLoaded with searchQuery='buy' and all other
  //   properties copied from the current state
  //
  TodosLoaded copyWith({
    List<Todo>? todos,
    String? searchQuery,
    TodoCategory? selectedCategory,
    bool clearCategory = false,
    TodoPriority? selectedPriority,
    bool clearPriority = false,
  }) {
    return TodosLoaded(
      todos: todos ?? this.todos,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedPriority: clearPriority
          ? null
          : (selectedPriority ?? this.selectedPriority),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// ERROR STATE — Something went wrong
/// ═══════════════════════════════════════════════════════════════
/// Contains an error message that can be shown to the user.
///
/// IMPORTANT: We include 'message' in props because:
///   - If the same error occurs with a different message, UI should update
///   - BlocBuilder needs to know this state is "different" from the last error
///
/// UI behavior: Show error widget with retry button
///
class TodosError extends TodosState {
  final String message;

  const TodosError(this.message);

  @override
  List<Object?> get props => [message];
}

/// ═══════════════════════════════════════════════════════════════
/// ACTION STATES — One-time feedback states
/// ═══════════════════════════════════════════════════════════════
// These states represent one-time actions (like showing a SnackBar)
// After the UI handles them, the cubit goes back to TodosLoaded
//
// WHY NOT JUST USE TodosLoaded with a flag?
//   - Flags persist across rebuilds → SnackBar shows multiple times
//   - Action states are consumed once → SnackBar shows exactly once
//   - BlocListener handles these perfectly
//

/// A todo was successfully added
class TodoAdded extends TodosState {
  final Todo todo;
  const TodoAdded(this.todo);

  @override
  List<Object?> get props => [todo];
}

/// A todo was successfully updated
class TodoUpdated extends TodosState {
  final Todo todo;
  const TodoUpdated(this.todo);

  @override
  List<Object?> get props => [todo];
}

/// A todo was deleted (with undo capability)
class TodoDeleted extends TodosState {
  final Todo todo; // Keep the deleted todo for potential undo
  const TodoDeleted(this.todo);

  @override
  List<Object?> get props => [todo];
}

/// A todo's completion was toggled
class TodoCompletionToggled extends TodosState {
  final Todo todo;
  const TodoCompletionToggled(this.todo);

  @override
  List<Object?> get props => [todo];
}
