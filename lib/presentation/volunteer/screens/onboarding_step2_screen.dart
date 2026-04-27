import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/volunteer_profile.dart';
import '../../shared/widgets/shared_widgets.dart';

class OnboardingStep2Screen extends ConsumerStatefulWidget {
  final List<String> selectedSkills;

  const OnboardingStep2Screen({super.key, required this.selectedSkills});

  @override
  ConsumerState<OnboardingStep2Screen> createState() =>
      _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState
    extends ConsumerState<OnboardingStep2Screen> {
  ExperienceLevel? _selected;

  static const _levels = [
    (
      level: ExperienceLevel.student,
      title: 'Student',
      subtitle: 'Currently studying in a relevant field',
      icon: Icons.school_rounded,
      color: Color(0xFF7B61FF),
    ),
    (
      level: ExperienceLevel.junior,
      title: '1–5 Years',
      subtitle: 'Practising professional with some experience',
      icon: Icons.work_outline_rounded,
      color: Color(0xFF00BCD4),
    ),
    (
      level: ExperienceLevel.senior,
      title: '5–10 Years',
      subtitle: 'Senior practitioner with extensive experience',
      icon: Icons.verified_rounded,
      color: Color(0xFF43A047),
    ),
    (
      level: ExperienceLevel.expert,
      title: '10+ Years',
      subtitle: 'Expert — highly experienced specialist',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFF57C00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepProgressIndicator(currentStep: 2, totalSteps: 3),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Step 2 of 3',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Text('Your Experience\nLevel',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 6),
                    Text('This helps match you to the right assignments',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  itemCount: _levels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = _levels[i];
                    final isSelected = _selected == item.level;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient:
                            isSelected ? AppColors.cardGradient : null,
                        color: isSelected
                            ? null
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? item.color : AppColors.border,
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      item.color.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _selected = item.level),
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(item.icon,
                                    color: item.color, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                                color: isSelected
                                                    ? item.color
                                                    : null)),
                                    const SizedBox(height: 4),
                                    Text(item.subtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? item.color
                                    : AppColors.textHint,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _selected != null
                      ? () => context.push(AppRoutes.onboardingStep3, extra: {
                            'skills': widget.selectedSkills,
                            'experienceLevel': _selected!.name,
                          })
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
