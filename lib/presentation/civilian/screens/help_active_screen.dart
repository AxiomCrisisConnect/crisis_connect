import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/emergency_request.dart';
import '../../../data/models/assignment.dart';
import '../../shared/widgets/shared_widgets.dart';

class HelpActiveScreen extends ConsumerStatefulWidget {
  final String requestId;

  const HelpActiveScreen({super.key, required this.requestId});

  @override
  ConsumerState<HelpActiveScreen> createState() => _HelpActiveScreenState();
}

class _HelpActiveScreenState extends ConsumerState<HelpActiveScreen> {
  EmergencyRequest? _request;
  Assignment? _assignment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(emergencyRepositoryProvider);
    final req = await repo.getRequest(widget.requestId);
    final user = ref.read(currentUserProvider);
    List<Assignment> assignments = [];
    if (user != null) {
      assignments = await repo.getAssignmentsForCivilian(user.id);
    }
    final assignment = assignments
        .where((a) => a.emergencyRequestId == widget.requestId)
        .lastOrNull;
    if (mounted) {
      setState(() {
        _request = req;
        _assignment = assignment;
      });
    }
  }

  Future<void> _rateVolunteer(int rating) async {
    if (_assignment == null) return;
    final repo = ref.read(emergencyRepositoryProvider);
    await repo.rateVolunteer(_assignment!.id, rating, null);
    if (mounted) {
      ErrorSnackBar.showSuccess(context, 'Thank you for your feedback!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppHeader(
              title: 'Help Request',
              subtitle: 'We are matching your request with a volunteer.',
              showBack: true,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 20),

              // Confirmation card
              GlassCard(
                borderColor: AppColors.help,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.help.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.helpLight, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text('Request Submitted!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: AppColors.helpLight),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    if (_request?.helpCategory != null)
                      Text(
                        'Category: ${_request!.helpCategory!.label}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Location Map
              if (_request != null)
                LocationMap(
                  latitude: _request!.latitude,
                  longitude: _request!.longitude,
                  height: 200,
                  interactive: false,
                ),
              const SizedBox(height: 20),

              // Assigned volunteer
              if (_assignment != null)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Volunteer',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_assignment!.volunteerName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge),
                                Text(
                                  _assignment!.volunteerSkills.join(' · '),
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('En Route',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                GlassCard(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.help),
                      const SizedBox(height: 12),
                      Text('Finding nearest volunteer...',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Rate volunteer (shown after resolved)
              if (_assignment?.status == AssignmentStatus.resolved) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rate Your Volunteer',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text('How well did ${_assignment!.volunteerName} help you?',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return IconButton(
                            icon: Icon(Icons.star_rounded,
                                color: i < (
                                    _assignment!.volunteerRating ?? 0)
                                    ? Colors.amber
                                    : AppColors.textHint,
                                size: 36),
                            onPressed: () => _rateVolunteer(i + 1),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
