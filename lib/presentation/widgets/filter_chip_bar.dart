// =============================================================================
// FILE: lib/presentation/widgets/filter_chip_bar.dart
// =============================================================================
// PURPOSE: Horizontal scrollable chip bar for category/priority filtering
// WHY: Chips are the Material Design way to show filter options.
//      Each chip represents a category or priority level.
//      Tapping a chip activates the filter; tapping again deactivates it.
//
// BLOC CONNECTION:
//   When a chip is tapped, we call cubit.filterByCategory() or
//   cubit.filterByPriority(). The cubit emits a new TodosLoaded state
//   with the updated filter, and BlocBuilder rebuilds the filtered list.
//
//   UI → cubit.filterByCategory(Work) → Cubit emits TodosLoaded(selectedCategory: Work)
//      → BlocBuilder rebuilds → filteredTodos only shows Work category todos
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../data/models/todo_model.dart';
import '../../logic/todos_cubit.dart';
import '../../logic/todos_state.dart';

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodosCubit, TodosState>(
      // ═══════════════════════════════════════════════════════════
      // buildWhen — PERFORMANCE OPTIMIZATION
      // ═══════════════════════════════════════════════════════════
      // This tells BlocBuilder: "Only rebuild if the condition is true"
      // Without buildWhen, EVERY state change rebuilds this widget.
      // With buildWhen, we only rebuild when filter-related data changes.
      //
      // Example: If we emit a TodoAdded state, this widget doesn't need
      // to rebuild because the filter chips themselves haven't changed.
      // Only TodosLoaded with different filters needs a rebuild.
      //
      buildWhen: (previous, current) {
        // Only rebuild when we have TodosLoaded states with different filters
        if (previous is TodosLoaded && current is TodosLoaded) {
          return previous.selectedCategory != current.selectedCategory ||
              previous.selectedPriority != current.selectedPriority;
        }
        return current is TodosLoaded;
      },
      builder: (context, state) {
        if (state is! TodosLoaded) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category filters
            _buildSectionLabel('Category'),
            const SizedBox(height: AppDimens.spacing8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacing16,
                ),
                itemCount: TodoCategory.values.length + 1, // +1 for "All"
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimens.spacing8),
                itemBuilder: (context, index) {
                  // First chip is "All"
                  if (index == 0) {
                    return _buildFilterChip(
                      label: 'All',
                      icon: '📋',
                      isSelected: state.selectedCategory == null,
                      onSelected: () =>
                          context.read<TodosCubit>().filterByCategory(null),
                    );
                  }
                  final category = TodoCategory.values[index - 1];
                  return _buildFilterChip(
                    label: category.displayName,
                    icon: category.icon,
                    isSelected: state.selectedCategory == category,
                    onSelected: () =>
                        context.read<TodosCubit>().filterByCategory(category),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimens.spacing12),
            // Priority filters
            _buildSectionLabel('Priority'),
            const SizedBox(height: AppDimens.spacing8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacing16,
                ),
                itemCount: TodoPriority.values.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimens.spacing8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFilterChip(
                      label: 'All',
                      icon: '⚡',
                      isSelected: state.selectedPriority == null,
                      onSelected: () =>
                          context.read<TodosCubit>().filterByPriority(null),
                    );
                  }
                  final priority = TodoPriority.values[index - 1];
                  return _buildFilterChip(
                    label: priority.displayName,
                    icon: priority == TodoPriority.high
                        ? '🔴'
                        : priority == TodoPriority.medium
                        ? '🟠'
                        : '🟢',
                    isSelected: state.selectedPriority == priority,
                    onSelected: () =>
                        context.read<TodosCubit>().filterByPriority(priority),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacing16),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text('$icon $label'),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}
