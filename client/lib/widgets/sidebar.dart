import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (int index) {
        onItemSelected(index);
      },
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance),
          label: Text('Pots'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.trending_down),
          label: Text('Drawdowns'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.access_time),
          label: Text('State'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart),
          label: Text('Sim'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        ),
      ],

      
      // 👇 LOGOUT BUTTON
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: () {
            context.read<AuthProvider>().logout();
          },
        ),
      ),

    );
  }
}
