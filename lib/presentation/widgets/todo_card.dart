// =============================================================================
// FILE: lib/presentation/widgets/todo_card.dart
// =============================================================================
// PURPOSE: Individual todo item card with swipe-to-delete, animations
// WHY: Each todo in the list is rendered as this card.
//      It handles: display, checkbox, swipe, tap-to-edit
//
// BLOC CONNECTION:
//   - Checkbox: calls cubit.toggleCompletion(id)
//   - Swipe delete: calls cubit.deleteTodo(id)
//   - After delete: cubit emits TodoDeleted state
//   - BlocListener in HomeScreen shows SnackBar with "Undo"
//   - Undo: calls cubit.undoDelete(todo)
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/todo_model.dart';
import '../../logic/todos_cubit.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final int index; // For staggered animation delay

  const TodoCard({super.key, required this.todo, required this.index});

  @override
  Widget build(BuildContext context) {
    // ═══════════════════════════════════════════════════════════════
    // Dismissible — Swipe to delete
    // ═══════════════════════════════════════════════════════════════
    // Wrapping the card in Dismissible enables swipe gestures.
    // When swiped, onDismissed is called → we delete the todo.
    //
    return Dismissible(
      key: ValueKey(todo.id), // Unique key for each Dismissible
      direction: DismissDirection.endToStart, // Only swipe left
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spacing24),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing16,
          vertical: AppDimens.spacing4,
        ),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        child: const Icon(
          Icons.delete,
          color: AppColors.textOnPrimary,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog before deleting
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Todo?'),
                content: Text(
                  'Are you sure you want to delete "${todo.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        // ═══════════════════════════════════════════════════════════
        // context.read<TodosCubit>() — Access cubit to call methods
        // ═══════════════════════════════════════════════════════════
        // We use context.read because we're TRIGGERING an action,
        // not listening for state changes.
        //
        context.read<TodosCubit>().deleteTodo(todo.id);
      },
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    // Priority color for the left border
    final priorityColor = _getPriorityColor(todo.priority);
    final isOverdue =
        DateFormatter.isOverdue(todo.dueDate) && !todo.isCompleted;

    return GestureDetector(
      onTap: () => _navigateToEdit(context),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing16,
          vertical: AppDimens.spacing4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(
            color: isOverdue
                ? AppColors.error.withOpacity(0.3)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority color indicator on the left
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimens.radiusMedium),
                    bottomLeft: Radius.circular(AppDimens.radiusMedium),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Checkbox + Title
                      Row(
                        children: [
                          // Completion checkbox
                          _buildCheckbox(context),
                          const SizedBox(width: AppDimens.spacing12),
                          // Title
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: todo.isCompleted
                                    ? AppColors.textDisabled
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Category icon
                          Text(
                            todo.category.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      // Description (if any)
                      if (todo.description.isNotEmpty) ...[
                        const SizedBox(height: AppDimens.spacing4),
                        Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: todo.isCompleted
                                ? AppColors.textDisabled
                                : AppColors.textSecondary,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                      // Bottom row: Date + Priority badge
                      const SizedBox(height: AppDimens.spacing8),
                      Row(
                        children: [
                          // Due date
                          if (todo.dueDate != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDate(todo.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: AppDimens.spacing12),
                          ],
                          // Created date
                          if (todo.dueDate == null) ...[
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDate(todo.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppDimens.spacing12),
                          ],
                          const Spacer(),
                          // Priority badge
                          _buildPriorityBadge(todo.priority),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ═══════════════════════════════════════════════════════════
        // Toggle completion via cubit
        // ═══════════════════════════════════════════════════════════
        context.read<TodosCubit>().toggleCompletion(todo.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: todo.isCompleted ? AppColors.success : Colors.transparent,
          border: Border.all(
            color: todo.isCompleted
                ? AppColors.success
                : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: todo.isCompleted
            ? const Icon(Icons.check, size: 16, color: AppColors.textOnPrimary)
            : null,
      ),
    );
  }

  Widget _buildPriorityBadge(TodoPriority priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacing8,
        vertical: AppDimens.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return AppColors.highPriority;
      case TodoPriority.medium:
        return AppColors.mediumPriority;
      case TodoPriority.low:
        return AppColors.lowPriority;
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).pushNamed('/add-edit', arguments: todo);
  }
}
