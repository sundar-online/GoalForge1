import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'flaticon_icon.dart';

class FlaticonPickerDialog extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const FlaticonPickerDialog({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  static Future<String?> show(BuildContext context, String currentKey) {
    return showDialog<String>(
      context: context,
      builder: (context) => FlaticonPickerDialog(
        selectedKey: currentKey,
        onSelected: (key) => Navigator.of(context).pop(key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'Flaticon Icon Selector',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20.0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'Select a high-quality vector icon for your goal system:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13.0,
              ),
            ),
            const SizedBox(height: 20.0),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: FlaticonCatalog.items.map((item) {
                    final isSelected = item.key.toLowerCase() == selectedKey.toLowerCase();
                    return InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: () => onSelected(item.key),
                      child: Container(
                        width: 72.0,
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            FlaticonIcon(
                              iconKey: item.key,
                              size: 28.0,
                              color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              item.name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10.0,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
