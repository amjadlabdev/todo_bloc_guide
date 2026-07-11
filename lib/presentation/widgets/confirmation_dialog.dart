// =============================================================================
// FILE: lib/presentation/widgets/confirmation_dialog.dart
// =============================================================================
// PURPOSE: Reusable confirmation dialog for destructive actions (delete)
// WHY: We want a consistent, beautiful dialog across the app
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = AppStrings.confirm,
    required this.onConfirm,
    this.isDangerous = true,
  });

  /// Static helper to show the dialog
  /// WHY: Makes calling code cleaner:
  ///   ConfirmationDialog.show(context, title: 'Delete?', onConfirm: () => ...);
  ///   vs:
  ///   showDialog(context: context, builder: (_) => ConfirmationDialog(...));
  ///
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    required VoidCallback onConfirm,
    bool isDangerous = true,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isDangerous ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isDangerous ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
