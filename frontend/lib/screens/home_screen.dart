import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:corpticketz/screens/employee_dashboard.dart';
import 'package:corpticketz/screens/agent_dashboard.dart';
import 'package:corpticketz/screens/login_screen.dart';
import 'package:corpticketz/widgets/app_drawer.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    Widget content;
    if (user?.role == 'Employee') {
        content = const EmployeeDashboard();
    } else if (user?.role == 'Agent' || user?.role == 'Lead' || user?.role == 'GlobalAdmin') {
        content = const AgentDashboard();
    } else {
        // Fallback
        content = Center(child: Text("Welcome ${user?.role} - Dashboard under construction"));
    }

    return GlassScaffold(
      appBar: AppBar(
        title: Text('${user?.role} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: content,
    );
  }
}
