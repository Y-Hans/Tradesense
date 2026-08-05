import 'package:flutter/material.dart';

/// A custom Scaffold that enforces the design system's background and default AppBar behavior.
///
/// Example usage:
/// ```dart
/// AppScaffold(
///   title: 'Journal',
///   body: JournalList(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  /// The body of the scaffold
  final Widget body;
  
  /// Optional title for the app bar
  final String? title;
  
  /// Optional trailing widget in the app bar (e.g. settings icon)
  final Widget? trailing;
  
  /// Optional bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Whether to show the back button
  final bool showBackButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.trailing,
    this.bottomNavigationBar,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: title != null || trailing != null
          ? AppBar(
              automaticallyImplyLeading: showBackButton,
              title: title != null
                  ? Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  : null,
              actions: trailing != null ? [trailing!, const SizedBox(width: 16)] : null,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
