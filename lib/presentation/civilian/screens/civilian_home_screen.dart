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

class CivilianHomeScreen extends ConsumerStatefulWidget {
  const CivilianHomeScreen({super.key});

  @override
  ConsumerState<CivilianHomeScreen> createState() =>
      _CivilianHomeScreenState();
}

class _CivilianHomeScreenState extends ConsumerState<CivilianHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSOSLoading = false;
  int _currentTab = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Active request state — loaded on init and refreshed after actions
  EmergencyRequest? _activeRequest;
  Assignment? _activeAssignment;
  bool _loadingActive = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveRequest());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveRequest() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _loadingActive = false);
      return;
    }
    try {
      final repo = ref.read(emergencyRepositoryProvider);
      final active = await repo.getActiveCivilianRequest(user.id);

      Assignment? assignment;
      if (active != null) {
        final assignments = await repo.getAssignmentsForCivilian(user.id);
        assignment = assignments
            .where((a) =>
                a.emergencyRequestId == active.id &&
                (a.status == AssignmentStatus.pending ||
                    a.status == AssignmentStatus.accepted))
            .lastOrNull;
      }

      if (mounted) {
        setState(() {
          _activeRequest = active;
          _activeAssignment = assignment;
          _loadingActive = false;
        });
      }
    } catch (e) {
      // Firestore may throw if a composite index hasn't been created yet.
      // In that case we degrade gracefully — show the normal SOS UI.
      debugPrint('[CivilianHome] _loadActiveRequest error: $e');
      if (mounted) {
        setState(() {
          _activeRequest = null;
          _activeAssignment = null;
          _loadingActive = false;
        });
      }
    }
  }

  Future<void> _triggerSOS() async {
    // Block if already active
    if (_activeRequest != null) {
      ErrorSnackBar.show(
        context,
        'You already have an active emergency request. Cancel it first.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.sos, size: 28),
            const SizedBox(width: 10),
            const Text('Confirm SOS'),
          ],
        ),
        content: const Text(
          'Are you sure? This will immediately alert emergency responders and dispatch the nearest available volunteers to your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sos),
            child: const Text('YES, SEND SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSOSLoading = true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final pos = await locationService.getCurrentLocation();
      if (pos == null) {
        setState(() => _isSOSLoading = false);
        if (mounted) {
          ErrorSnackBar.show(
            context,
            'Location is required to send SOS. Please enable location access.',
          );
        }
        return;
      }
      final user = ref.read(currentUserProvider)!;
      final request = EmergencyRequest(
        id: const Uuid().v4(),
        type: EmergencyType.sos,
        priority: EmergencyPriority.high,
        civilianId: user.id,
        civilianName: user.name,
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestamp: DateTime.now(),
        status: EmergencyStatus.active,
      );

      final repo = ref.read(emergencyRepositoryProvider);
      await repo.createEmergencyRequest(request);

      if (!mounted) return;
      setState(() {
        _isSOSLoading = false;
        _activeRequest = request;
        _activeAssignment = null;
      });
      context.push(AppRoutes.sosActive, extra: request.id);
    } catch (e) {
      setState(() => _isSOSLoading = false);
      if (mounted) ErrorSnackBar.show(context, 'Failed to send SOS: $e');
    }
  }

  Future<void> _cancelActiveRequest() async {
    if (_activeRequest == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure the situation has been resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep Active'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.sos)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(emergencyRepositoryProvider).updateRequestStatus(
        _activeRequest!.id, EmergencyStatus.cancelled);
    if (mounted) {
      setState(() {
        _activeRequest = null;
        _activeAssignment = null;
      });
      ErrorSnackBar.showSuccess(context, 'Request cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (_loadingActive) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.sos)),
      );
    }



    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: IndexedStack(
            index: _currentTab,
            children: [
              _buildHomeTab(context, user?.name ?? 'Civilian'),
              const SOSHistoryTab(),
              _buildProfileTabCivilian(context, user?.name ?? ''),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
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

  Widget _buildHomeTab(BuildContext context, String name) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadActiveRequest,
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
                    Text('Hello,',
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergency services are monitoring your area.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Active Emergency or SOS Button ──
          if (_activeRequest != null)
            GestureDetector(
              onTap: () {
                final route = _activeRequest!.type == EmergencyType.sos
                    ? AppRoutes.sosActive
                    : AppRoutes.helpActive;
                context.push(route, extra: _activeRequest!.id);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      (_activeRequest!.type == EmergencyType.sos ? AppColors.sos : AppColors.help).withValues(alpha: 0.15),
                      (_activeRequest!.type == EmergencyType.sos ? AppColors.sos : AppColors.help).withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: (_activeRequest!.type == EmergencyType.sos ? AppColors.sos : AppColors.help).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_activeRequest!.type == EmergencyType.sos ? AppColors.sos : AppColors.help).withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated Pulse Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_activeRequest!.type == EmergencyType.sos ? AppColors.sos : AppColors.help).withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: ScaleTransition(
                          scale: _pulseAnim,
                          child: Icon(
                            _activeRequest!.type == EmergencyType.sos ? Icons.my_location_rounded : Icons.handshake_rounded,
                            color: _activeRequest!.type == EmergencyType.sos ? AppColors.sosLight : AppColors.helpLight,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Text details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _activeRequest!.type == EmergencyType.sos ? AppColors.sos : AppColors.helpLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _activeRequest!.type == EmergencyType.sos ? 'LIVE SOS ALERT' : 'LIVE HELP REQUEST',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: _activeRequest!.type == EmergencyType.sos ? AppColors.sosLight : AppColors.helpLight,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tracking responders in real-time',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view map & status',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                           BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ── SOS Button ──
            Center(
              child: ScaleTransition(
                scale: _pulseAnim,
                child: GestureDetector(
                  onTap: _isSOSLoading ? null : _triggerSOS,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.sosGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sos.withValues(alpha: 0.5),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.sos.withValues(alpha: 0.2),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: _isSOSLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_rounded,
                                  color: Colors.white, size: 56),
                              const SizedBox(height: 8),
                              Text(
                                'SOS',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 36),
                              ),
                              Text(
                                'EMERGENCY',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Colors.white70,
                                        letterSpacing: 3,
                                        fontSize: 11),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('Tap to alert emergency responders immediately',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),

            // Request Help button
            GestureDetector(
              onTap: () => context.push(AppRoutes.helpRequest),
              child: GlassCard(
                borderColor: AppColors.help,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.help.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.handshake_rounded,
                          color: AppColors.helpLight, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Request Help',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppColors.helpLight)),
                          const SizedBox(height: 4),
                          Text('Non-emergency assistance — medical, food, etc.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Safety tips — always visible
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('Safety Tips',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  'Stay calm — help is on the way after SOS.',
                  'Move to a safe location if possible.',
                  'Keep your phone charged.',
                ].map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(tip,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabCivilian(BuildContext context, String name) {
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
                  color: AppColors.helpLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Civilian',
                    style: TextStyle(
                        color: AppColors.helpLight,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _InfoBanner(
          icon: Icons.medical_information_rounded,
          title: 'Medical Profile',
          subtitle: 'Pre-fill your medical info for faster assistance',
          color: Colors.red,
        ),
        const SizedBox(height: 10),
        const _InfoBanner(
          icon: Icons.contacts_rounded,
          title: 'Emergency Contacts',
          subtitle: 'Add contacts to be notified during SOS',
          color: Colors.blue,
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

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.textHint, size: 16),
        ],
      ),
    );
  }
}

// ─── SOS History Tab ──────────────────────────────────────────────────────────

class SOSHistoryTab extends ConsumerStatefulWidget {
  const SOSHistoryTab({super.key});

  @override
  ConsumerState<SOSHistoryTab> createState() => _SOSHistoryTabState();
}

class _SOSHistoryTabState extends ConsumerState<SOSHistoryTab> {
  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return FutureBuilder<List<EmergencyRequest>>(
      future: user != null
          ? ref.read(emergencyRepositoryProvider).getCivilianRequests(user.id)
          : Future.value([]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        final requests = snap.data ?? [];
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Request History',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 20),
              if (requests.isEmpty)
                GlassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No requests yet',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text('Your SOS and help requests will appear here',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ...requests.map((r) => _HistoryTile(request: r)),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final EmergencyRequest request;
  const _HistoryTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final isSOS = request.type == EmergencyType.sos;
    final color = isSOS ? AppColors.sos : AppColors.help;
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
            child: Icon(
              isSOS ? Icons.warning_rounded : Icons.handshake_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isSOS
                        ? 'SOS Alert'
                        : (request.helpCategory?.label ?? 'Help Request'),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(_formatDate(request.timestamp),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _StatusBadge(status: request.status),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  final EmergencyStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      EmergencyStatus.resolved => AppColors.success,
      EmergencyStatus.cancelled => AppColors.sos,
      EmergencyStatus.active => AppColors.helpLight,
      EmergencyStatus.assigned => AppColors.accent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
