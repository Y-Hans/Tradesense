import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity/connectivity_provider.dart';
import '../../core/services/connectivity/connectivity_status.dart';
import '../constants/app_strings.dart';
import 'status_banner.dart';

/// Thin domain wrapper that watches [connectivityProvider]
/// and maps network state to [StatusBanner].
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider.select(
        (status) => status == ConnectivityStatus.offline,
      ),
    );

    return StatusBanner(
      title: AppStrings.offlineBannerTitle,
      subtitle: AppStrings.offlineBannerSubtitle,
      icon: const Icon(Icons.warning_amber_rounded),
      severity: BannerSeverity.warning,
      isVisible: isOffline,
    );
  }
}
