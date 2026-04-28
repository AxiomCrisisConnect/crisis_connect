import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/volunteer_profile.dart';
import '../../shared/widgets/shared_widgets.dart';

class OnboardingStep1Screen extends ConsumerStatefulWidget {
  const OnboardingStep1Screen({super.key});

  @override
  ConsumerState<OnboardingStep1Screen> createState() =>
      _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends ConsumerState<OnboardingStep1Screen> {
  // Map of category -> Set of selected subcategories (or just the category itself)
  final Map<String, Set<String>> _selected = {};
  final Set<String> _expanded = {};

  void _toggleCategory(String category) {
    setState(() {
      if (_expanded.contains(category)) {
        _expanded.remove(category);
      } else {
        _expanded.add(category);
      }
    });
  }

  void _toggleSubcategory(String category, String sub) {
    setState(() {
      _selected.putIfAbsent(category, () => {});
      if (_selected[category]!.contains(sub)) {
        _selected[category]!.remove(sub);
        if (_selected[category]!.isEmpty) _selected.remove(category);
      } else {
        _selected[category]!.add(sub);
      }
    });
  }

  void _toggleTopLevel(String category) {
    setState(() {
      if (_selected.containsKey(category) &&
          _selected[category]!.contains(category)) {
        _selected.remove(category);
      } else {
        _selected[category] = {category};
      }
    });
  }

  List<String> get _flatSkills {
    final skills = <String>[];
    for (final entry in _selected.entries) {
      for (final sub in entry.value) {
        skills.add(
            sub == entry.key ? entry.key : '${entry.key}:$sub');
      }
    }
    return skills;
  }

  bool get _isValid => _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                children: [
                    ...SkillCategory.categories.entries.map((entry) {
                      final cat = entry.key;
                      final subs = entry.value;
                      final hasSubs = subs.isNotEmpty;
                      final isExpanded = _expanded.contains(cat);
                      final hasSelection = _selected.containsKey(cat) &&
                          _selected[cat]!.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          borderColor: hasSelection
                              ? AppColors.accent
                              : AppColors.border,
                          child: Column(
                            children: [
                              InkWell(
                                onTap: hasSubs
                                    ? () => _toggleCategory(cat)
                                    : () => _toggleTopLevel(cat),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      _categoryIcon(cat),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(cat,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge),
                                      ),
                                      if (hasSelection)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${_selected[cat]!.length} selected',
                                            style: const TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      if (hasSubs)
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                  .keyboard_arrow_down_rounded,
                                          color: AppColors.textSecondary,
                                        )
                                      else
                                        Icon(
                                          hasSelection
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: hasSelection
                                              ? AppColors.accent
                                              : AppColors.textHint,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (hasSubs && isExpanded) ...[
                                const Divider(
                                    color: AppColors.border,
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16),
                                ...subs.map((sub) {
                                  final isChecked = _selected[cat]
                                          ?.contains(sub) ??
                                      false;
                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (_) =>
                                        _toggleSubcategory(cat, sub),
                                    title: Text(sub,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    activeColor: AppColors.accent,
                                    checkColor: AppColors.background,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isValid
                    ? () => context.push(AppRoutes.onboardingStep2,
                        extra: _flatSkills)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepProgressIndicator(currentStep: 1, totalSteps: 3),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Step 1 of 3',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('What are your\nskills?',
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 6),
          Text('Select all areas where you can help',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _categoryIcon(String cat) {
    final icons = {
      'Medical': Icons.medical_services_rounded,
      'Rescue': Icons.emergency_rounded,
      'Engineering': Icons.engineering_rounded,
      'Food & Logistics': Icons.local_dining_rounded,
      'Mental Health Support': Icons.psychology_rounded,
      'Communication & Coordination': Icons.radio_rounded,
    };
    final colors = {
      'Medical': Colors.red,
      'Rescue': Colors.orange,
      'Engineering': Colors.blue,
      'Food & Logistics': Colors.green,
      'Mental Health Support': Colors.purple,
      'Communication & Coordination': Colors.teal,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (colors[cat] ?? AppColors.accent).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icons[cat] ?? Icons.star_rounded,
          color: colors[cat] ?? AppColors.accent, size: 24),
    );
  }
}
