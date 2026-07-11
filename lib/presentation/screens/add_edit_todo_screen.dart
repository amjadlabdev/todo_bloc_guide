// =============================================================================
// FILE: lib/presentation/screens/add_edit_todo_screen.dart
// =============================================================================
// PURPOSE: Screen for adding a new todo or editing an existing one
// WHY: Single screen for both Add and Edit reduces code duplication.
//      We differentiate by checking if a Todo object was passed as argument.
//
// ═══════════════════════════════════════════════════════════════
// FORM VALIDATION — Where does it belong?
// ═══════════════════════════════════════════════════════════════
//
// Question: Should the Cubit validate the form?
// Answer: NO! Form validation is UI logic, not business logic.
//
// The Cubit's job: "Add this todo to the database" (business logic)
// The UI's job: "Make sure the title field isn't empty before calling add" (UI logic)
//
// WHY?
//   1. Form validation depends on BuildContext, controllers, and focus nodes
//   2. Different platforms might have different validation rules
//   3. The Cubit should trust it's receiving valid data from the UI
//   4. The Cubit CAN still do business validation (e.g., "duplicate title")
//
// Flow:
//   1. User fills form
//   2. User taps "Save"
//   3. UI validates form (title required, etc.)
//   4. If valid → UI calls cubit.addTodo() or cubit.updateTodo()
//   5. Cubit saves to database and emits new state
//   6. BlocListener in HomeScreen shows success SnackBar
//   7. This screen pops back to HomeScreen
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/todo_model.dart';
import '../../logic/todos_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo; // null = Add mode, non-null = Edit mode

  const AddEditTodoScreen({super.key, this.todo});

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  // ───────── Form State ─────────
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Default values for new todos
  TodoPriority _selectedPriority = TodoPriority.medium;
  TodoCategory _selectedCategory = TodoCategory.personal;
  DateTime? _dueDate;
  bool _clearDueDate = false;

  // ───────── Mode Detection ─────────
  // If a todo was passed in, we're in EDIT mode
  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    // If editing, populate form with existing todo data
    if (isEditing) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _selectedPriority = widget.todo!.priority;
      _selectedCategory = widget.todo!.category;
      _dueDate = widget.todo!.dueDate;
    }
  }

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks!
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? AppStrings.editTodoTitle : AppStrings.addTodoTitle,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Title Field ───
              CustomTextField(
                label: AppStrings.titleLabel,
                hint: AppStrings.titleHint,
                controller: _titleController,
                validator: (value) {
                  // UI validation — not in the cubit!
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.titleRequired;
                  }
                  return null; // null = valid
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimens.spacing20),

              // ─── Description Field ───
              CustomTextField(
                label: AppStrings.descriptionLabel,
                hint: AppStrings.descriptionHint,
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppDimens.spacing24),

              // ─── Priority Selection ───
              _buildSectionTitle(AppStrings.priorityLabel),
              const SizedBox(height: AppDimens.spacing8),
              _buildPrioritySelector(),
              const SizedBox(height: AppDimens.spacing24),

              // ─── Category Selection ───
              _buildSectionTitle(AppStrings.categoryLabel),
              const SizedBox(height: AppDimens.spacing8),
              _buildCategorySelector(),
              const SizedBox(height: AppDimens.spacing24),

              // ─── Due Date ───
              _buildSectionTitle(AppStrings.dueDate),
              const SizedBox(height: AppDimens.spacing8),
              _buildDatePicker(),
              const SizedBox(height: AppDimens.spacing48),

              // ─── Save Button ───
              CustomButton(
                label: isEditing ? AppStrings.save : AppStrings.add,
                icon: isEditing ? Icons.save : Icons.add,
                onPressed: _submitForm,
              ),

              // ─── Delete Button (only in edit mode) ───
              if (isEditing) ...[
                const SizedBox(height: AppDimens.spacing12),
                CustomButton(
                  label: AppStrings.delete,
                  icon: Icons.delete,
                  type: ButtonType.danger,
                  onPressed: _deleteTodo,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIORITY SELECTOR — Visual toggle buttons
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPrioritySelector() {
    return Row(
      children: TodoPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        final color = _getPriorityColor(priority);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacing4),
            child: ChoiceChip(
              label: Text(priority.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPriority = priority);
                }
              },
              selectedColor: color.withOpacity(0.2),
              backgroundColor: AppColors.background,
              side: BorderSide(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY SELECTOR — Visual grid of options
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppDimens.spacing8,
      runSpacing: AppDimens.spacing8,
      children: TodoCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return ChoiceChip(
          label: Text('${category.icon} ${category.displayName}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedCategory = category);
            }
          },
          selectedColor: AppColors.primary.withOpacity(0.15),
          backgroundColor: AppColors.background,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DATE PICKER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          setState(() {
            _dueDate = picked;
            _clearDueDate = false;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacing16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.textFieldBorderRadius),
          border: Border.all(
            color: _dueDate != null ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _dueDate != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimens.spacing12),
            Text(
              _dueDate != null
                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                  : 'Select a due date (optional)',
              style: TextStyle(
                color: _dueDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (_dueDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _dueDate = null;
                    _clearDueDate = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FORM SUBMISSION
  // ═══════════════════════════════════════════════════════════════
  void _submitForm() {
    // Step 1: Validate form (UI validation)
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    // Step 2: Call cubit method based on mode
    // ═══════════════════════════════════════════════════════════════
    // WHY context.read<TodosCubit>() here?
    // We're triggering a method call. We don't need the widget to
    // rebuild based on the cubit's state — we're about to navigate
    // away from this screen anyway!
    // ═══════════════════════════════════════════════════════════════
    final cubit = context.read<TodosCubit>();

    if (isEditing) {
      cubit.updateTodo(
        id: widget.todo!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: _dueDate,
        clearDueDate: _clearDueDate,
      );
    } else {
      cubit.addTodo(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: _dueDate,
      );
    }

    // Step 3: Navigate back to home screen
    // The cubit will emit the new state, and BlocListener in
    // HomeScreen will show the success SnackBar
    Navigator.of(context).pop();
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE TODO
  // ═══════════════════════════════════════════════════════════════
  void _deleteTodo() {
    context.read<TodosCubit>().deleteTodo(widget.todo!.id);
    Navigator.of(context).pop();
  }

  // ───────── Helpers ─────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
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
}
