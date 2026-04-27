import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/providers.dart';
import '../../../data/models/volunteer_profile.dart';
import '../../shared/widgets/shared_widgets.dart';

class OnboardingStep3Screen extends ConsumerStatefulWidget {
  final List<String> selectedSkills;
  final String experienceLevel;

  const OnboardingStep3Screen({
    super.key,
    required this.selectedSkills,
    required this.experienceLevel,
  });

  @override
  ConsumerState<OnboardingStep3Screen> createState() =>
      _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState
    extends ConsumerState<OnboardingStep3Screen> {
  String? _uploadedFileName;
  bool _isLoading = false;

  ExperienceLevel get _expLevel => ExperienceLevel.values.firstWhere(
        (e) => e.name == widget.experienceLevel,
        orElse: () => ExperienceLevel.student,
      );

  bool get _isStudent => _expLevel == ExperienceLevel.student;

  String get _uploadLabel =>
      _isStudent ? 'Upload Student ID Card' : 'Upload Professional License / Certificate';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _uploadedFileName = result.files.first.name);
    }
  }

  Future<void> _complete({bool skip = false}) async {
    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // TODO: If file picked, upload to Firebase Storage and get URL
    // final url = skip ? null : await _uploadToStorage(pickedFile);

    final profile = VolunteerProfile(
      userId: user.id,
      skills: widget.selectedSkills,
      experienceLevel: _expLevel,
      licenseUrl: skip ? null : _uploadedFileName, // TODO: replace with real URL
      isAvailable: false,
      onboardingComplete: true,
    );

    await ref.read(authNotifierProvider.notifier).saveVolunteerProfile(profile);

    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go(AppRoutes.volunteerHome);
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepProgressIndicator(currentStep: 3, totalSteps: 3),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Step 3 of 3',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                      Text('Verify your\nCredentials',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 6),
                      Text('Upload proof to earn a verified badge (optional)',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            children: [
                              Icon(
                                _isStudent ? Icons.badge_rounded : Icons.workspace_premium_rounded,
                                size: 48,
                                color: AppColors.accent,
                              ),
                              const SizedBox(height: 16),
                              Text(_uploadLabel,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text(
                                'Accepted: PDF, JPG, PNG (max 10MB)',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (_uploadedFileName != null)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.success),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.success, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _uploadedFileName!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: AppColors.successLight),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 18,
                                            color: AppColors.textSecondary),
                                        onPressed: () => setState(
                                            () => _uploadedFileName = null),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text('Choose File'),
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        PrimaryButton(
                          label: _uploadedFileName != null
                              ? 'Submit & Finish'
                              : 'Upload & Finish',
                          icon: Icons.check_rounded,
                          onPressed: _uploadedFileName != null
                              ? () => _complete(skip: false)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => _complete(skip: true),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
