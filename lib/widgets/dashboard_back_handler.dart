import 'package:flutter/material.dart';

/// A widget that handles back button navigation to prevent going back to login page
/// unless the user explicitly logs out
class DashboardBackHandler extends StatelessWidget {
  final Widget child;
  final String dashboardRoute;

  const DashboardBackHandler({
    Key? key,
    required this.child,
    required this.dashboardRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        
        // Instead of popping, navigate to dashboard
        Navigator.pushReplacementNamed(context, dashboardRoute);
      },
      child: child,
    );
  }
}

