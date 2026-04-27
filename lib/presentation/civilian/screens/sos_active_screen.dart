import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/emergency_request.dart';
import '../../shared/widgets/shared_widgets.dart';

class SOSActiveScreen extends ConsumerStatefulWidget {
  final String requestId;

  const SOSActiveScreen({super.key, required this.requestId});

  @override
  ConsumerState<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen>
    with SingleTickerProviderStateMixin {
  EmergencyRequest? _request;
  bool _loading = true;
  late AnimationController _flashCtrl;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final repo = ref.read(emergencyRepositoryProvider);
    final req = await repo.getRequest(widget.requestId);
    if (mounted) {
      setState(() {
      _request = req;
      _loading = false;
    });
    }
  }

  Future<void> _cancelSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel SOS?'),
        content:
            const Text('Are you sure the situation has been resolved?'),
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
    if (confirmed == true && _request != null) {
      await ref.read(emergencyRepositoryProvider).updateRequestStatus(
          _request!.id, EmergencyStatus.cancelled);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.sos)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              // Pulsing alert indicator
              Center(
                child: FadeTransition(
                  opacity: _flashCtrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sos.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.sos, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_rounded,
                            color: AppColors.sos, size: 20),
                        const SizedBox(width: 8),
                        Text('SOS ACTIVE',
                            style: TextStyle(
                                color: AppColors.sos,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Help is on the way
              GlassCard(
                borderColor: AppColors.success,
                child: Column(
                  children: [
                    const Icon(Icons.local_hospital_rounded,
                        size: 48, color: AppColors.successLight),
                    const SizedBox(height: 12),
                    Text('Help is on the way!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: AppColors.successLight),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency responders have been notified and are heading to your location.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // ETA mock
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: AppColors.successLight, size: 20),
                          const SizedBox(width: 8),
                          Text('Estimated Arrival: ',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text('8–12 minutes',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.successLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Assigned Volunteer Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Responders',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 14),
                    _VolunteerTile(
                      name: 'Dr. Arun Kumar',
                      skills: 'Medical · Rescue',
                      eta: '8 min',
                    ),
                    const Divider(color: AppColors.divider, height: 24),
                    _VolunteerTile(
                      name: 'Priya Nair',
                      skills: 'Rescue · Communication',
                      eta: '10 min',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Location card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.sos, size: 20),
                        const SizedBox(width: 8),
                        Text('Your Location',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // TODO: Replace with real Google Maps widget
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_rounded,
                                size: 40, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text(
                              _request != null
                                  ? '${_request!.latitude.toStringAsFixed(4)}, ${_request!.longitude.toStringAsFixed(4)}'
                                  : 'Location captured',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'TODO: Integrate google_maps_flutter here',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _cancelSOS,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel SOS (False Alarm)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  final String name;
  final String skills;
  final String eta;

  const _VolunteerTile({
    required this.name,
    required this.skills,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person_rounded,
              color: AppColors.accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(skills, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('ETA $eta',
              style: const TextStyle(
                  color: AppColors.successLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
      ],
    );
  }
}
