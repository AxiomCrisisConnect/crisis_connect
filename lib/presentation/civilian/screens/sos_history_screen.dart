import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'civilian_home_screen.dart';

class SOSHistoryScreen extends ConsumerWidget {
  const SOSHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppBackground(
        child: const SOSHistoryTab(),
      ),
    );
  }
}

