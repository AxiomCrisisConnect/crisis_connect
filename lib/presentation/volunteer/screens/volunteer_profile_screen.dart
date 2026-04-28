import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../shared/widgets/shared_widgets.dart';

class VolunteerProfileScreen extends ConsumerStatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  ConsumerState<VolunteerProfileScreen> createState() =>
      _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState
    extends ConsumerState<VolunteerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(volunteerProfileProvider);

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppHeader(
              title: 'My Profile',
              subtitle: 'Volunteer credentials and skills',
              showBack: true,
              onBack: () => Navigator.pop(context),
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
                  Text(user?.name ?? '—',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(user?.phoneNumber ?? '—',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (profile != null) ...[
              _SectionHeader('Skills'),
              const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              _SectionHeader('Experience'),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Text(profile.experienceLevelLabel,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('License'),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile.licenseUrl ?? 'No license uploaded',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}
