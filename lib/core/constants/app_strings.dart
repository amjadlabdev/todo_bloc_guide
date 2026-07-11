// =============================================================================
// FILE: lib/core/constants/app_strings.dart
// =============================================================================
// PURPOSE: All user-facing strings in one place
// WHY:
//   1. If you need to change "Add Todo" to "New Task", change it once here
//   2. Makes localization/translation easy — just swap this file
//   3. Prevents typos from propagating (compiler catches wrong names)
// BLOC RELEVANCE: Strings are UI-layer data. BLoC deals with state,
//                 not display text. But error messages in state ARE strings.
// =============================================================================

class AppStrings {
  // Private constructor — this is a namespace, not an object
  AppStrings._();

  // ───────── App Info ─────────
  static const String appName = 'Todo BLoC Guide';
  static const String appTagline = 'Learn BLoC by Building';

  // ───────── Navigation ─────────
  static const String homeTitle = 'My Todos';
  static const String addTodoTitle = 'Add New Todo';
  static const String editTodoTitle = 'Edit Todo';

  // ───────── Actions ─────────
  static const String add = 'Add';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String cancel = 'Cancel';
  static const String undo = 'Undo';
  static const String confirm = 'Confirm';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String clearAll = 'Clear All';

  // ───────── Todo Form ─────────
  static const String titleLabel = 'Title';
  static const String titleHint = 'What do you need to do?';
  static const String titleRequired = 'Title is required';
  static const String descriptionLabel = 'Description';
  static const String descriptionHint = 'Add some details...';
  static const String priorityLabel = 'Priority';
  static const String categoryLabel = 'Category';

  // ───────── Priorities ─────────
  static const String highPriority = 'High';
  static const String mediumPriority = 'Medium';
  static const String lowPriority = 'Low';

  // ───────── Categories ─────────
  static const String all = 'All';
  static const String work = 'Work';
  static const String personal = 'Personal';
  static const String shopping = 'Shopping';
  static const String health = 'Health';
  static const String education = 'Education';

  // ───────── Status Messages ─────────
  static const String loading = 'Loading...';
  static const String noTodosYet = 'No todos yet!';
  static const String addYourFirstTodo =
      'Tap the + button to add your first todo';
  static const String noSearchResults = 'No results found';
  static const String tryDifferentSearch = 'Try a different search term';

  // ───────── Success Messages ─────────
  static const String todoAdded = 'Todo added successfully! 🎉';
  static const String todoUpdated = 'Todo updated! ✏️';
  static const String todoDeleted = 'Todo deleted 🗑️';
  static const String todoCompleted = 'Well done! 🎉';
  static const String todoUncompleted = 'Todo marked as incomplete';

  // ───────── Error Messages ─────────
  static const String errorLoading = 'Failed to load todos';
  static const String errorAdding = 'Failed to add todo';
  static const String errorUpdating = 'Failed to update todo';
  static const String errorDeleting = 'Failed to delete todo';
  static const String errorGeneric = 'Something went wrong';

  // ───────── Confirmation ─────────
  static const String deleteConfirmTitle = 'Delete Todo?';
  static const String deleteConfirmMessage =
      'This action cannot be undone. Are you sure you want to delete this todo?';

  // ───────── Date Labels ─────────
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String dueDate = 'Due Date';
}
