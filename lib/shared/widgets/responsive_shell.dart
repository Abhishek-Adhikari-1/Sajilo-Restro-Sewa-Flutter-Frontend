import 'package:flutter/material.dart';

class ResponsiveShell extends StatefulWidget {
  final List<NavigationDestination> destinations;
  final List<Widget> screens;

  const ResponsiveShell({
    super.key,
    required this.destinations,
    required this.screens,
  }) : assert(destinations.length == screens.length, 'Destinations and screens must have the same length.');

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile view (width < 600)
        if (constraints.maxWidth < 600) {
          return Scaffold(
            body: widget.screens[_currentIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: widget.destinations,
            ),
          );
        }

        // Web/Tablet view (NavigationRail)
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                destinations: widget.destinations.map((dest) {
                  return NavigationRailDestination(
                    icon: dest.icon,
                    selectedIcon: dest.selectedIcon,
                    label: Text(dest.label),
                  );
                }).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: widget.screens[_currentIndex],
              ),
            ],
          ),
        );
      },
    );
  }
}
