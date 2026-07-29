import 'package:flutter/material.dart';
import 'global_status_region.dart';

/// Top-level application shell that wraps the router navigation tree.
///
/// Places [GlobalStatusRegion] above the active route widget, ensuring
/// global status banners render consistently across all screens.
class AppShell extends StatelessWidget {
  final Widget? child;

  const AppShell({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GlobalStatusRegion(),
          Expanded(
            child: child ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
