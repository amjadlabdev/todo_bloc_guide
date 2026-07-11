// =============================================================================
// FILE: lib/presentation/widgets/custom_button.dart
// =============================================================================
// PURPOSE: Reusable button widget with consistent styling
// WHY: Instead of duplicating ElevatedButton.styleFrom() everywhere,
//      we create one reusable component. Change it here → changes everywhere.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

enum ButtonType { primary, secondary, danger, text }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // If loading, show a spinner instead of the label
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textOnPrimary,
            ),
          )
        : Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimens.iconSmall),
                const SizedBox(width: AppDimens.spacing8),
              ],
              Text(label),
            ],
          );

    // Disable button when loading
    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: isExpanded ? double.infinity : null,
          height: AppDimens.buttonHeight,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimens.buttonBorderRadius,
                ),
              ),
            ),
            child: child,
          ),
        );
      case ButtonType.secondary:
        return SizedBox(
          width: isExpanded ? double.infinity : null,
          height: AppDimens.buttonHeight,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimens.buttonBorderRadius,
                ),
              ),
            ),
            child: child,
          ),
        );
      case ButtonType.danger:
        return SizedBox(
          width: isExpanded ? double.infinity : null,
          height: AppDimens.buttonHeight,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimens.buttonBorderRadius,
                ),
              ),
            ),
            child: child,
          ),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: child,
        );
    }
  }
}
