import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:corpticketz/screens/home_screen.dart';
import 'package:corpticketz/screens/master/departments_screen.dart' as dept_real;
import 'package:corpticketz/screens/master/users_screen.dart' as users_real;
import 'package:corpticketz/screens/master/countries_screen.dart';
import 'package:corpticketz/screens/master/branches_screen.dart';
import 'package:corpticketz/screens/master/categories_screen.dart';
import 'package:corpticketz/screens/master/priorities_screen.dart';
import 'package:corpticketz/screens/tickets_screen.dart';
import 'package:corpticketz/screens/reports_screen.dart';
import 'package:corpticketz/screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isGlobalAdmin = user?.role == 'GlobalAdmin';
    final isManager = user?.role == 'Manager';
    final canManageMaster = isGlobalAdmin || isManager;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.fullName ?? 'User'),
                accountEmail: Text(user?.email ?? 'email@example.com'),
                currentAccountPicture: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(child: Image.asset('assets/images/logo.png')),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0056D2).withOpacity(0.8), const Color(0xFF002F75).withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.white),
                title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => const HomeScreen())
                  );
                },
              ),
              if (isGlobalAdmin || isManager || user?.role == 'Lead' || user?.role == 'Agent')
                ListTile(
                  leading: const Icon(Icons.confirmation_number, color: Colors.white),
                  title: const Text('Tickets', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen())),
                ),
              if (isGlobalAdmin || isManager)
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.white),
                  title: const Text('Reports', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                ),
              if (canManageMaster) ...[
                const Divider(color: Colors.white24),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text('Master Data', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.public, color: Colors.white),
                  title: const Text('Countries', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CountriesScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.white),
                  title: const Text('Branches', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BranchesScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.domain, color: Colors.white),
                  title: const Text('Departments', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const dept_real.DepartmentsScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.white),
                  title: const Text('Users', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const users_real.UsersScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.category, color: Colors.white),
                  title: const Text('Ticket Categories', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.low_priority, color: Colors.white),
                  title: const Text('Ticket Priorities', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrioritiesScreen())),
                ),
              ],
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  authProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
