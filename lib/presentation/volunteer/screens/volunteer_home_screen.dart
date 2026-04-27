import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/volunteer_profile.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/emergency_request.dart';
import '../../shared/widgets/shared_widgets.dart';


class VolunteerHomeScreen extends ConsumerStatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  ConsumerState<VolunteerHomeScreen> createState() =>
      _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends ConsumerState<VolunteerHomeScreen> {
  Assignment? _activeAssignment;
  bool _loadingAssignment = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveAssignment();
  }

  Future<void> _loadActiveAssignment() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(emergencyRepositoryProvider);
    final a = await repo.getActiveAssignmentForVolunteer(user.id);
    if (mounted) {
      setState(() {
        _activeAssignment = a;
        _loadingAssignment = false;
      });
    }
  }

  Future<void> _markResolved() async {
    if (_activeAssignment == null) return;
    final repo = ref.read(emergencyRepositoryProvider);
    await repo.updateAssignmentStatus(
      _activeAssignment!.id,
      AssignmentStatus.resolved,
      resolvedAt: DateTime.now(),
    );
    await repo.updateRequestStatus(
      _activeAssignment!.emergencyRequestId,
      EmergencyStatus.resolved,
    );
    if (mounted) {
      setState(() => _activeAssignment = null);
      ErrorSnackBar.showSuccess(context, 'Crisis marked as resolved. Thank you!');
    }
  }

  Future<void> _acceptAssignment() async {
    if (_activeAssignment == null) return;
    final repo = ref.read(emergencyRepositoryProvider);
    await repo.updateAssignmentStatus(
        _activeAssignment!.id, AssignmentStatus.accepted);
    setState(() {
      _activeAssignment =
          _activeAssignment!.copyWith(status: AssignmentStatus.accepted);
    });
  }

  Future<void> _declineAssignment() async {
    if (_activeAssignment == null) return;
    final repo = ref.read(emergencyRepositoryProvider);
    await repo.updateAssignmentStatus(
        _activeAssignment!.id, AssignmentStatus.declined);
    setState(() => _activeAssignment = null);
    // TODO: Trigger reassignment in backend to next volunteer in queue
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(volunteerProfileProvider);
    final isAvailable = ref.watch(availabilityProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: IndexedStack(
            index: _currentTab,
            children: [
              _buildMainTab(context, user?.name ?? 'Volunteer', profile, isAvailable),
              const AssignmentHistoryTab(),
              _buildProfileTab(context, user?.name ?? '', profile),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTab(BuildContext context, String name,
      VolunteerProfile? profile, bool isAvailable) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadActiveAssignment,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(name,
                        style: Theme.of(context).textTheme.displayMedium),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.crisis_alert_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Availability toggle
          GlassCard(
            borderColor: isAvailable ? AppColors.success : AppColors.border,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isAvailable ? AppColors.success : AppColors.textHint)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.location_on_rounded
                        : Icons.location_off_rounded,
                    color: isAvailable ? AppColors.success : AppColors.textHint,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable ? 'I am Available' : 'I am Unavailable',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isAvailable
                                  ? AppColors.successLight
                                  : AppColors.textHint,
                            ),
                      ),
                      Text(
                        isAvailable
                            ? 'Location tracking active (every 3 min)'
                            : 'Toggle to receive emergency assignments',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (_) async {
                    if (profile != null) {
                      await ref
                          .read(availabilityProvider.notifier)
                          .toggle(profile);
                      if (!isAvailable) {
                        // Request background location permission when enabling
                        await ref
                            .read(locationServiceProvider)
                            .requestAlwaysPermission();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active assignment
          if (_loadingAssignment)
            const Center(child: CircularProgressIndicator(color: AppColors.accent))
          else if (_activeAssignment != null)
            _ActiveAssignmentCard(
              assignment: _activeAssignment!,
              onAccept: _acceptAssignment,
              onDecline: _declineAssignment,
              onResolved: _markResolved,
            )
          else
            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text('No Active Assignments',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    isAvailable
                        ? 'You\'ll be notified when help is needed nearby'
                        : 'Mark yourself as available to receive assignments',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Skills summary
          if (profile != null && profile.skills.isNotEmpty) ...[
            Text('Your Skills',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .map((s) => Chip(
                        label: Text(s.replaceAll(':', ' › ')),
                        avatar: const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accent),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTab(
      BuildContext context, String name, VolunteerProfile? profile) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(name, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Volunteer',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600)),
              ),
              if (profile != null) ...[
                const SizedBox(height: 12),
                Text(profile.experienceLevelLabel,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(
          icon: Icons.badge_rounded,
          label: 'Experience',
          value: profile?.experienceLevelLabel ?? '—',
        ),
        _InfoTile(
          icon: Icons.workspace_premium_rounded,
          label: 'License',
          value: profile?.licenseUrl ?? 'Not uploaded',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.sos,
            side: const BorderSide(color: AppColors.sos),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Text('$label: ',
              style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _ActiveAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onResolved;

  const _ActiveAssignmentCard({
    required this.assignment,
    required this.onAccept,
    required this.onDecline,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = assignment.status == AssignmentStatus.pending;
    return GlassCard(
      borderColor: AppColors.sos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sos.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? '⚡ NEW ASSIGNMENT' : '🚨 ACTIVE',
                  style: const TextStyle(
                      color: AppColors.sosLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(assignment.assignedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Emergency Assignment',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          _DetailRow(
              icon: Icons.person_rounded, text: assignment.civilianName),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.location_on_rounded,
            text:
                '${assignment.emergencyLatitude.toStringAsFixed(4)}, ${assignment.emergencyLongitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.star_rounded,
            text: assignment.volunteerSkills.join(', '),
          ),
          const SizedBox(height: 16),
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ),
          ] else ...[
            PrimaryButton(
              label: 'Mark as Resolved',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              onPressed: onResolved,
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// ─── Assignment History Tab ──────────────────────────────────────────────────

class AssignmentHistoryTab extends ConsumerWidget {
  const AssignmentHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return FutureBuilder<List<Assignment>>(
      future: user != null
          ? ref.read(emergencyRepositoryProvider).getAssignmentsForVolunteer(user.id)
          : Future.value([]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        final assignments = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Assignment History',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 20),
            if (assignments.isEmpty)
              GlassCard(
                child: Column(
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No past assignments yet',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              )
            else
              ...assignments.map((a) => _AssignmentHistoryTile(assignment: a)),
          ],
        );
      },
    );
  }
}

class _AssignmentHistoryTile extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentHistoryTile({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(assignment.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(assignment.status), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.civilianName,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  _formatDate(assignment.assignedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              assignment.status.name.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AssignmentStatus s) {
    switch (s) {
      case AssignmentStatus.resolved:
        return AppColors.success;
      case AssignmentStatus.cancelled:
      case AssignmentStatus.declined:
        return AppColors.sos;
      case AssignmentStatus.accepted:
        return AppColors.accent;
      case AssignmentStatus.pending:
        return AppColors.helpLight;
    }
  }

  IconData _statusIcon(AssignmentStatus s) {
    switch (s) {
      case AssignmentStatus.resolved:
        return Icons.check_circle_rounded;
      case AssignmentStatus.cancelled:
      case AssignmentStatus.declined:
        return Icons.cancel_rounded;
      case AssignmentStatus.accepted:
        return Icons.assignment_turned_in_rounded;
      case AssignmentStatus.pending:
        return Icons.pending_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
