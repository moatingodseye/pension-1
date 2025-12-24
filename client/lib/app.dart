import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pension_pots_screen.dart';
import 'screens/drawdowns_screen.dart';
import 'screens/state_pension_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/sidebar.dart';
import 'core/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pension Web App',
      theme: appTheme,
      home: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          if (!auth.loggedIn) {
            return const LoginScreen();
          }
          return const HomeContainer();
        },
      ),
    );
  }
}

class HomeContainer extends StatefulWidget {
  const HomeContainer({super.key});

  @override
  _HomeContainerState createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    PensionPotsScreen(),
    DrawdownsScreen(),
    StatePensionScreen(),
    SimulationScreen(),
    AdminScreen(),
  ];

  void onSidebarIndexChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: onSidebarIndexChanged,
          ),
          Expanded(child: screens[selectedIndex]),
        ],
      ),
    );
  }
}
