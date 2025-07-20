import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_provider.dart';
import '../utils/app_theme.dart';

class PriorityFilterChip extends StatelessWidget {
  final Priority priority;

  const PriorityFilterChip({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final isSelected = todoProvider.selectedPriority == priority;
        final priorityText = _getPriorityText(priority);
        final priorityColor = AppTheme.getPriorityColor(priorityText);

        return FilterChip(
          selected: isSelected,
          label: Text(priorityText),
          onSelected: (selected) {
            if (selected) {
              todoProvider.filterByPriority(priority);
            } else {
              todoProvider.filterByPriority(null);
            }
          },
          backgroundColor: Colors.grey.shade100,
          selectedColor: priorityColor.withOpacity(0.2),
          checkmarkColor: priorityColor,
          labelStyle: TextStyle(
            color: isSelected ? priorityColor : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? priorityColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        );
      },
    );
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }
}
