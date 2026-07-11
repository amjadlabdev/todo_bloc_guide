// =============================================================================
// FILE: lib/presentation/screens/home_screen.dart
// =============================================================================
// PURPOSE: Main screen of the app — displays the todo list
// WHY: This is where BLoC concepts come together in the UI layer!
//
// ═══════════════════════════════════════════════════════════════
// HOW BLoC WORKS IN THIS SCREEN — THE COMPLETE PICTURE
// ═══════════════════════════════════════════════════════════════
//
// 1. BlocProvider (in app.dart) makes TodosCubit available to this screen
//
// 2. BlocConsumer combines:
//    - BlocBuilder: Rebuilds UI when state changes (show list, loading, error)
//    - BlocListener: Executes one-time actions (show SnackBar on add/delete)
//
// 3. State flow in this screen:
//    ┌─────────────────────────────────────────────────────┐
//    │  TodosInitial  → Show loading, trigger loadTodos()  │
//    │  TodosLoading  → Show spinner                       │
//    │  TodosLoaded   → Show todo list + stats             │
//    │  TodosError    → Show error with retry              │
//    │  TodoAdded     → Show success SnackBar (Listener)   │
//    │  TodoDeleted   → Show undo SnackBar (Listener)      │
//    └─────────────────────────────────────────────────────┘
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/todo_model.dart';
import '../../logic/todos_cubit.dart';
import '../../logic/todos_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/todo_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // ═══════════════════════════════════════════════════════════════
    // INITIALIZING DATA
    // ═══════════════════════════════════════════════════════════════
    // We load todos in initState because:
    //   1. We need data as soon as the screen appears
    //   2. initState runs exactly ONCE when the widget is created
    //
    // WHY use context.read here?
    //   - We're TRIGGERING an action (loadTodos)
    //   - We don't want this widget to REBUILD when the state changes
    //     from TodosInitial → TodosLoading → TodosLoaded
    //   - BlocBuilder below handles the rebuilding
    //   - Using context.watch here would cause an infinite loop:
    //     build → state changes → rebuild → initState again → ...
    //
    // Note: We use Future.microtask to ensure the cubit is available
    // in the widget tree before we call it.
    //
    Future.microtask(() {
      context.read<TodosCubit>().loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.homeTitle),
      actions: [
        // Stats indicator
        BlocBuilder<TodosCubit, TodosState>(
          builder: (context, state) {
            if (state is TodosLoaded) {
              final completed = state.completedCount;
              final total = state.todos.length;
              return Padding(
                padding: const EdgeInsets.only(right: AppDimens.spacing16),
                child: Center(
                  child: Text(
                    '$completed/$total',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BODY — The main content area using BlocConsumer
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBody() {
    // ═══════════════════════════════════════════════════════════════
    // BlocConsumer = BlocBuilder + BlocListener
    // ═══════════════════════════════════════════════════════════════
    // WHY BlocConsumer instead of separate BlocBuilder and BlocListener?
    //   - It's more efficient than nesting them
    //   - It ensures builder and listener use the same state instance
    //   - Less nesting = cleaner code
    //
    // BlocConsumer takes TWO required functions:
    //   1. listener: For one-time side effects (SnackBars, Navigation, Dialogs)
    //   2. builder: For rebuilding UI based on state
    //
    return BlocConsumer<TodosCubit, TodosState>(
      // ───────── listenWhen ─────────
      // Optimization: Only call listener when this returns true
      // We only care about ACTION states (TodoAdded, TodoDeleted, etc.)
      // and ERROR states for showing SnackBars. We don't need to listen
      // to TodosLoading or TodosLoaded (those just affect the UI).
      //
      listenWhen: (previous, current) {
        return current is TodoAdded ||
            current is TodoUpdated ||
            current is TodoDeleted ||
            current is TodoCompletionToggled ||
            current is TodosError;
      },

      // ───────── listener ─────────
      // Executes ONE-TIME actions based on state changes
      // This does NOT rebuild the widget tree
      //
      listener: (context, state) {
        // ═══════════════════════════════════════════════════════════
        // HANDLING ACTION STATES
        // ═══════════════════════════════════════════════════════════
        // Action states (TodoAdded, TodoDeleted, etc.) are perfect for
        // BlocListener because they represent "events that happened" that
        // the user should be notified about, but they shouldn't directly
        // determine what the UI looks like.
        //
        if (state is TodoAdded) {
          _showSnackBar(context, AppStrings.todoAdded);
        } else if (state is TodoUpdated) {
          _showSnackBar(context, AppStrings.todoUpdated);
        } else if (state is TodoDeleted) {
          // Special case: Show UNDO SnackBar for deleted todos
          _showUndoSnackBar(context, state.todo);
        } else if (state is TodoCompletionToggled) {
          final msg = state.todo.isCompleted
              ? AppStrings.todoUncompleted
              : AppStrings.todoCompleted;
          _showSnackBar(context, msg);
        } else if (state is TodosError) {
          _showSnackBar(context, state.message, isError: true);
        }
      },

      // ───────── builder ─────────
      // Rebuilds the widget tree when state changes
      // This is where we decide what to SHOW based on the state
      //
      builder: (context, state) {
        // ═══════════════════════════════════════════════════════════
        // STATE PATTERN MATCHING
        // ═══════════════════════════════════════════════════════════
        // We use "is" checks to determine the state type.
        // Each state type renders a different UI.
        //
        // WHY not switch(state)?
        //   - Dart's switch on runtime types requires exhaustive cases
        //   - With "is", we get automatic type promotion
        //   - Example: after "if (state is TodosLoaded)", we can access
        //     state.todos directly without casting!
        //
        if (state is TodosInitial || state is TodosLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is TodosError) {
          return _buildErrorState(state.message);
        }

        if (state is TodosLoaded) {
          // If we're in an action state, we still want to show the
          // loaded UI underneath. Action states happen "on top of" data states.
          // We need to extract the data state for rendering.
          //
          // Note: Because our cubit re-emits TodosLoaded after action states,
          // we'll always have TodosLoaded here when there's data.
          //
          return _buildTodoList(state);
        }

        // Fallback — should never reach here
        return const SizedBox.shrink();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TODO LIST BUILDER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTodoList(TodosLoaded state) {
    // Use filteredTodos (computed property) instead of all todos
    final displayTodos = state.filteredTodos;

    return Column(
      children: [
        // Search bar
        const SearchBarWidget(),
        // Filter chips
        const FilterChipBar(),
        // Progress indicator
        if (state.todos.isNotEmpty) _buildProgressIndicator(state),
        const SizedBox(height: AppDimens.spacing8),
        // Todo list or empty state
        Expanded(
          child: displayTodos.isEmpty
              ? _buildEmptyState(state)
              : AnimationLimiter(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      bottom: AppDimens.spacing80, // Space for FAB
                    ),
                    itemCount: displayTodos.length,
                    itemBuilder: (context, index) {
                      // ═══════════════════════════════════════════════════════
                      // STAGGERED ANIMATIONS
                      // ═══════════════════════════════════════════════════════
                      // Each todo card animates in with a slight delay.
                      // AnimationConfiguration + SlideTransition + FadeTransition
                      // create a beautiful cascading entrance effect.
                      //
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: TodoCard(
                              todo: displayTodos[index],
                              index: index,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS INDICATOR — Shows completion progress
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProgressIndicator(TodosLoaded state) {
    final completed = state.completedCount;
    final total = state.todos.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacing16,
        vertical: AppDimens.spacing8,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: progress == 1.0
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacing8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE — Shown when list is empty or no search results
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmptyState(TodosLoaded state) {
    // Different empty states depending on whether filters are applied
    if (state.searchQuery.isNotEmpty ||
        state.selectedCategory != null ||
        state.selectedPriority != null) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: AppStrings.noSearchResults,
        subtitle: AppStrings.tryDifferentSearch,
        onAction: () => context.read<TodosCubit>().clearFilters(),
        actionLabel: 'Clear Filters',
      );
    }

    return EmptyState(
      icon: Icons.checklist_rounded,
      title: AppStrings.noTodosYet,
      subtitle: AppStrings.addYourFirstTodo,
      onAction: () => _navigateToAddEdit(),
      actionLabel: 'Add Todo',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimens.spacing16),
            Text(
              AppStrings.errorGeneric,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.spacing8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.spacing24),
            ElevatedButton.icon(
              onPressed: () => context.read<TodosCubit>().loadTodos(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FLOATING ACTION BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddEdit(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Todo'),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION HELPER
  // ═══════════════════════════════════════════════════════════════
  void _navigateToAddEdit([Todo? todo]) {
    Navigator.of(context).pushNamed(
      '/add-edit',
      arguments: todo, // null for add, Todo object for edit
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SNACKBAR HELPERS
  // ═══════════════════════════════════════════════════════════════
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UNDO SNACKBAR — Shows after deleting a todo
  // ═══════════════════════════════════════════════════════════════
  // This is a CRITICAL BLoC pattern! The UI gives the user an "Undo"
  // option after a delete. When they tap Undo, we call the cubit to
  // restore the todo. The cubit handles the database restoration and
  // emits a new state with the todo back in the list.
  //
  // WHY is this handled in the UI, not the cubit?
  //   - The cubit doesn't know about SnackBars or "Undo" actions
  //   - The cubit just emits TodoDeleted(state) with the deleted todo
  //   - The UI decides HOW to present that to the user
  //   - If the user taps Undo, the UI calls cubit.undoDelete(todo)
  //   - This keeps business logic (undo database operation) in the cubit
  //     and presentation logic (showing a button) in the UI
  //
  void _showUndoSnackBar(BuildContext context, Todo todo) {
    ScaffoldMessenger.of(context).clearSnackBars(); // Clear previous
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.todoDeleted),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppStrings.undo,
          textColor: AppColors.primary,
          onPressed: () {
            // User tapped Undo — tell cubit to restore the todo!
            context.read<TodosCubit>().undoDelete(todo);
          },
        ),
      ),
    );
  }
}
