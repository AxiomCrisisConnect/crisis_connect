import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/emergency_request.dart';
import '../../../data/models/assignment.dart';
import '../../shared/widgets/shared_widgets.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const LiveTrackingScreen({super.key, required this.requestId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  EmergencyRequest? _request;
  Assignment? _assignment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(emergencyRepositoryProvider);
      final req = await repo.getRequest(widget.requestId);

      Assignment? assign;
      if (req != null) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final assignments = await repo.getAssignmentsForCivilian(user.id);
          assign = assignments
              .where((a) =>
                  a.emergencyRequestId == req.id &&
                  (a.status == AssignmentStatus.pending ||
                      a.status == AssignmentStatus.accepted))
              .lastOrNull;
        }
      }

      if (mounted) {
        setState(() {
          _request = req;
          _assignment = assign;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelRequest() async {
    if (_request == null) return;
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
        _request!.id, EmergencyStatus.cancelled);
    if (mounted) {
      ErrorSnackBar.showSuccess(context, 'Request cancelled.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.sos)),
      );
    }

    if (_request == null || _request!.status == EmergencyStatus.cancelled || _request!.status == EmergencyStatus.resolved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alert Ended')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              Text('This request is no longer active.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          )
        ),
      );
    }

    final isSOS = _request!.type == EmergencyType.sos;
    final accentColor = isSOS ? AppColors.sos : AppColors.help;
    final accentLight = isSOS ? AppColors.sosLight : AppColors.helpLight;
    final isAssigned = _request!.status == EmergencyStatus.assigned ||
        _assignment?.status == AssignmentStatus.accepted;

    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          Positioned.fill(
            child: LocationMap(
              latitude: _request!.latitude,
              longitude: _request!.longitude,
              height: null,
              borderRadius: 0,
              interactive: true,
              zoom: 16.0,
            ),
          ),

          // Floating Header (Status + Back + Refresh)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'back_btn',
                      onPressed: () => context.pop(),
                      backgroundColor: AppColors.surface,
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: isSOS ? 'SOS ACTIVE' : 'HELP REQUEST ACTIVE',
                      color: accentColor,
                      pulsing: true,
                    ),
                  ],
                ),
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  onPressed: () {
                    setState(() => _loading = true);
                    _loadData();
                  },
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                ),
              ],
            ),
          ),

          // Bottom Sheet Card
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: GlassCard(
              borderColor: accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAssigned ? Icons.person_pin_rounded : Icons.search_rounded,
                        size: 16,
                        color: isAssigned ? AppColors.success : AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAssigned
                              ? (_assignment != null
                                  ? 'Volunteer assigned: ${_assignment!.volunteerName}'
                                  : 'Volunteer assigned')
                              : 'Searching for nearest volunteers...',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: isAssigned ? AppColors.success : AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_request!.helpCategory != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_request!.helpCategory!.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancelRequest,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
