import 'package:flutter/material.dart';
import '../../shared/widgets/connectivity_banner.dart';

/// Container for top-level global status banners.
///
/// Houses [ConnectivityBanner] and provides an extension point for future
/// global status banners (maintenance mode, server outages, feature flags)
/// without modifying [AppShell].
class GlobalStatusRegion extends StatelessWidget {
  const GlobalStatusRegion({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConnectivityBanner(),
        // Future global status banners (MaintenanceBanner, OutageBanner) can be added here
      ],
    );
  }
}
