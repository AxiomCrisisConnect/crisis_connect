import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/providers.dart';
import '../../../data/models/emergency_request.dart';
import '../../../data/models/assignment.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'package:uuid/uuid.dart';

class HelpRequestScreen extends ConsumerStatefulWidget {
  const HelpRequestScreen({super.key});

  @override
  ConsumerState<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends ConsumerState<HelpRequestScreen> {
  HelpCategory? _selectedCategory;
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider)!;
      final loc = await ref.read(locationServiceProvider).getCurrentLocation();
      final lat = loc?.latitude ?? 12.9716;
      final lng = loc?.longitude ?? 77.5946;

      final request = EmergencyRequest(
        id: const Uuid().v4(),
        type: EmergencyType.help,
        priority: EmergencyPriority.low,
        civilianId: user.id,
        civilianName: user.name,
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        status: EmergencyStatus.active,
        helpCategory: _selectedCategory,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      final repo = ref.read(emergencyRepositoryProvider);
      await repo.createEmergencyRequest(request);

      // Auto-assign nearest volunteer with matching skill
      final assignment = Assignment(
        id: const Uuid().v4(),
        emergencyRequestId: request.id,
        volunteerId: 'mock_volunteer_2',
        volunteerName: 'Kiran Rao',
        volunteerSkills: [_selectedCategory!.matchingSkill],
        civilianId: user.id,
        civilianName: user.name,
        emergencyLatitude: lat,
        emergencyLongitude: lng,
        assignedAt: DateTime.now(),
        status: AssignmentStatus.pending,
      );
      await repo.createAssignment(assignment);

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.pushReplacement(AppRoutes.helpActive, extra: request.id);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ErrorSnackBar.show(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: _isLoading,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary),
                        onPressed: () => context.pop(),
                      ),
                      Text('Request Help',
                          style: Theme.of(context).textTheme.headlineLarge),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text('What kind of help\ndo you need?',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 6),
                      Text('Select the category that best fits your situation',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      ...HelpCategory.values.map((cat) {
                        final selected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight
                                      .withValues(alpha: 0.15)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: selected ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(_categoryIcon(cat),
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    size: 24),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(cat.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              color: selected
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary)),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.accent, size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Optional description
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Additional Details (optional)',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _descCtrl,
                              maxLines: 3,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                hintText: 'Describe the situation briefly...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Request Help',
                        icon: Icons.handshake_rounded,
                        color: AppColors.help,
                        onPressed: _selectedCategory != null ? _submit : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(HelpCategory cat) {
    switch (cat) {
      case HelpCategory.medical:
        return Icons.medical_services_rounded;
      case HelpCategory.engineering:
        return Icons.engineering_rounded;
      case HelpCategory.food:
        return Icons.local_dining_rounded;
      case HelpCategory.mentalHealth:
        return Icons.psychology_rounded;
      case HelpCategory.communication:
        return Icons.radio_rounded;
      case HelpCategory.other:
        return Icons.help_outline_rounded;
    }
  }
}
