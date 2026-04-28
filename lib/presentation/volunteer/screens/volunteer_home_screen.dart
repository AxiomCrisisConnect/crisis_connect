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
    if (user == null) {
      if (mounted) setState(() => _loadingAssignment = false);
      return;
    }
    try {
      final repo = ref.read(emergencyRepositoryProvider);
      final a = await repo.getActiveAssignmentForVolunteer(user.id);
      if (mounted) {
        setState(() {
          _activeAssignment = a;
          _loadingAssignment = false;
        });
      }
    } catch (e) {
      debugPrint('[VolunteerHome] _loadActiveAssignment error: $e');
      if (mounted) {
        setState(() {
          _activeAssignment = null;
          _loadingAssignment = false;
        });
      }
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
      body: AppBackground(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildMainTab(context, user?.name ?? 'Volunteer', profile, isAvailable),
            const AssignmentHistoryTab(),
            _buildProfileTab(context, user?.name ?? '', profile),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          selectedFontSize: 11,
          unselectedFontSize: 11,
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
      backgroundColor: AppColors.surface,
      onRefresh: _loadActiveAssignment,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // ── Premium Header ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      label: isAvailable ? '● AVAILABLE' : '○ OFFLINE',
                      color: isAvailable ? AppColors.success : AppColors.textHint,
                      pulsing: isAvailable,
                    ),
                    const SizedBox(height: 10),
                    Text('Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(name.split(' ').first,
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable
                          ? 'You are live and visible to nearby civilians.'
                          : 'Go online to receive emergency assignments.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.crisis_alert_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Availability Toggle ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAvailable
                    ? [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.04)]
                    : [AppColors.surfaceVariant, AppColors.cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAvailable
                    ? AppColors.success.withValues(alpha: 0.5)
                    : AppColors.border,
                width: 1.5,
              ),
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isAvailable ? AppColors.success : AppColors.textHint)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.wifi_tethering_rounded
                        : Icons.wifi_tethering_off_rounded,
                    color: isAvailable ? AppColors.success : AppColors.textHint,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable ? 'Online & Accepting' : 'Offline',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isAvailable
                                  ? AppColors.successLight
                                  : AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAvailable
                            ? 'Location tracking active'
                            : 'Toggle to receive assignments',
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

          // ── Active Assignment ──
          if (_loadingAssignment)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded,
                        color: AppColors.success, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text('No Active Assignments',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    isAvailable
                        ? 'You\'ll be notified when help is needed nearby'
                        : 'Go online to start receiving emergency requests',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Skills ──
          if (profile != null && profile.skills.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Your Skills',
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          s.replaceAll(':', ' · '),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.accentLight,
                              ),
                        ),
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
        AppHeader(
          title: 'Profile',
          subtitle: 'Volunteer details and verification',
        ),
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
              const StatusBadge(label: 'Volunteer', color: AppColors.accent),
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
          _DetailRow(
            icon: Icons.star_rounded,
            text: assignment.volunteerSkills.join(', '),
          ),
          const SizedBox(height: 16),
          LocationMap(
            latitude: assignment.emergencyLatitude,
            longitude: assignment.emergencyLongitude,
            height: 160,
            interactive: false,
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
