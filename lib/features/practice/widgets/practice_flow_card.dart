import 'package:flutter/material.dart';
import 'package:veloria/utils/app_colors.dart';

enum PracticeStepType { slowPractice, rhythmTraining, toneListening }

class PracticeStepConfig {
  final PracticeStepType type;
  final String title;
  final String description;
  final IconData icon;

  const PracticeStepConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class PracticeFlowCard extends StatelessWidget {
  final List<PracticeStepConfig> steps;
  final Set<PracticeStepType> completedSteps;
  final ValueChanged<PracticeStepType>? onStepToggle;

  const PracticeFlowCard({
    super.key,
    required this.steps,
    required this.completedSteps,
    this.onStepToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.dynamicCard,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt, color: AppColors.dynamicPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今日練習流程',
                    style: TextStyle(
                      color: AppColors.dynamicTextDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map(
              (step) => _PracticeStepTile(
                config: step,
                completed: completedSteps.contains(step.type),
                onTap: () => onStepToggle?.call(step.type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeStepTile extends StatelessWidget {
  final PracticeStepConfig config;
  final bool completed;
  final VoidCallback? onTap;

  const _PracticeStepTile({
    required this.config,
    required this.completed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.dynamicPrimary.withValues(alpha: 0.08)
              : AppColors.dynamicBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? AppColors.dynamicPrimary.withValues(alpha: 0.3)
                : AppColors.dynamicPrimary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                color: AppColors.dynamicPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    config.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dynamicTextLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: completed,
              onChanged: (_) => onTap?.call(),
              activeColor: AppColors.dynamicPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
