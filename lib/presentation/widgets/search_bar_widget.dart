// =============================================================================
// FILE: lib/presentation/widgets/search_bar_widget.dart
// =============================================================================
// PURPOSE: Search bar with real-time filtering
// BLOC CONNECTION:
//   As user types, we call cubit.searchTodos(query).
//   The cubit emits TodosLoaded with updated searchQuery.
//   filteredTodos computed property filters based on the query.
//   BlocBuilder rebuilds the list automatically.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../logic/todos_cubit.dart';
import '../../logic/todos_state.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodosCubit, TodosState>(
      // Only rebuild when searchQuery changes
      buildWhen: (previous, current) {
        if (previous is TodosLoaded && current is TodosLoaded) {
          return previous.searchQuery != current.searchQuery;
        }
        return current is TodosLoaded;
      },
      builder: (context, state) {
        final searchQuery = state is TodosLoaded ? state.searchQuery : '';

        // Sync controller with cubit state
        if (_searchController.text != searchQuery) {
          _searchController.text = searchQuery;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacing16,
            vertical: AppDimens.spacing8,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              // ═══════════════════════════════════════════════════════
              // context.read<TodosCubit>() — Get cubit WITHOUT listening
              // ═══════════════════════════════════════════════════════
              // WHY context.read and not context.watch?
              //   - We're CALLING a method (triggering an action)
              //   - We DON'T want this widget to rebuild when the method
              //     causes a state change
              //   - The BlocBuilder above handles rebuilding
              //   - If we used context.watch here, we'd get infinite loops:
              //     onChanged → cubit changes state → widget rebuilds →
              //     onChanged fires again → cubit changes state → ...∞
              //
              context.read<TodosCubit>().searchTodos(query);
            },
            decoration: InputDecoration(
              hintText: 'Search todos...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        // Clear search in cubit
                        context.read<TodosCubit>().clearSearch();
                      },
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
