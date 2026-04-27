import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/assignment.dart';
import '../../shared/widgets/shared_widgets.dart';

class AssignmentHistoryScreen extends ConsumerWidget {
  const AssignmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment History')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<List<Assignment>>(
          future: user != null
              ? ref.read(emergencyRepositoryProvider).getAssignmentsForVolunteer(user.id)
              : Future.value([]),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            final assignments = snap.data ?? [];
            if (assignments.isEmpty) {
              return Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No assignments yet',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: assignments.length,
              itemBuilder: (_, i) => _AssignmentCard(assignment: assignments[i]),
            );
          },
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (assignment.status) {
      AssignmentStatus.resolved => AppColors.success,
      AssignmentStatus.cancelled || AssignmentStatus.declined => AppColors.sos,
      AssignmentStatus.accepted => AppColors.accent,
      AssignmentStatus.pending => AppColors.helpLight,
    };
    return GlassCard(
      borderColor: statusColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignment.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _fmt(assignment.assignedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Person: ${assignment.civilianName}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Skills: ${assignment.volunteerSkills.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall),
          if (assignment.resolvedAt != null) ...[
            const SizedBox(height: 4),
            Text('Resolved: ${_fmt(assignment.resolvedAt!)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (assignment.volunteerRating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Rating: '),
                ...List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 16,
                      color: i < assignment.volunteerRating!
                          ? Colors.amber
                          : AppColors.textHint),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
