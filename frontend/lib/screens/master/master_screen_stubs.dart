import 'package:flutter/material.dart';
import '../../widgets/glass_scaffold.dart';
import 'departments_screen.dart' as dept_real;
import 'users_screen.dart' as users_real;
import 'categories_screen.dart' as categories_real;

class PlaceholderMasterScreen extends StatelessWidget {
  final String title;
  const PlaceholderMasterScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white.withOpacity(0.05)),
      body: Center(
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text('$title Management - Coming Soon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}




class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});
  @override
  Widget build(BuildContext context) => const dept_real.DepartmentsScreen();
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context) => const users_real.UsersScreen();
}

class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderMasterScreen(title: 'Holidays');
}

class WorkingHoursScreen extends StatelessWidget {
  const WorkingHoursScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderMasterScreen(title: 'Working Hours');
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) => const categories_real.CategoriesScreen();
}
