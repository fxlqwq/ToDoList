import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_provider.dart';
import '../utils/app_theme.dart';

class CategoryFilterChip extends StatelessWidget {
  final Category category;

  const CategoryFilterChip({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final isSelected = todoProvider.selectedCategory == category;
        final categoryText = _getCategoryText(category);
        final categoryColor = AppTheme.getCategoryColor(categoryText);

        return FilterChip(
          selected: isSelected,
          label: Text(categoryText),
          onSelected: (selected) {
            if (selected) {
              todoProvider.filterByCategory(category);
            } else {
              todoProvider.filterByCategory(null);
            }
          },
          backgroundColor: Colors.grey.shade100,
          selectedColor: categoryColor.withValues(alpha: 0.2),
          checkmarkColor: categoryColor,
          labelStyle: TextStyle(
            color: isSelected ? categoryColor : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? categoryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        );
      },
    );
  }

  String _getCategoryText(Category category) {
    switch (category) {
      case Category.personal:
        return 'Personal';
      case Category.work:
        return 'Work';
      case Category.health:
        return 'Health';
      case Category.shopping:
        return 'Shopping';
      case Category.education:
        return 'Education';
      case Category.other:
        return 'Other';
    }
  }
}
