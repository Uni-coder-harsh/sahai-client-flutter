import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/skill_mesh_screen.dart';
import 'screens/sandbox_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const SahAiApp());
}

class SahAiApp extends StatelessWidget {
  const SahAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SahAI Cognitive Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.green,
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // Starts with AuthScreen
      home: const AuthScreen(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  final String userId;
  final String userName;

  const MainAppShell({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        userId: widget.userId,
        userName: widget.userName,
        onStartSandbox: () {
          setState(() {
            _selectedIndex = 2; // Jump to coding sandbox tab
          });
        },
      ),
      SkillMeshScreen(userId: widget.userId),
      SandboxScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.blueGrey[900]!, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.blueGrey[600],
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: Colors.greenAccent),
              label: 'Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined),
              activeIcon: Icon(Icons.account_tree_rounded, color: Colors.greenAccent),
              label: 'Skill Mesh',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.terminal_rounded),
              activeIcon: Icon(Icons.terminal_rounded, color: Colors.greenAccent),
              label: 'Sandbox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: Colors.greenAccent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
