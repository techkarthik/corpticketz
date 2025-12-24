import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _users;
  late Future<List<dynamic>> _departments;
  late Future<List<dynamic>> _branches;

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadMetadata();
  }

  void _refresh() {
    setState(() {
      _users = _api.getUsers();
    });
  }

  void _loadMetadata() {
    _departments = _api.getDepartments();
    _branches = _api.getBranches();
  }

  void _showUserDialog([dynamic user]) {
    final emailController = TextEditingController(text: user?['email']);
    final passController = TextEditingController();
    final nameController = TextEditingController(text: user?['full_name']);
    String? role = user?['role'] ?? 'Employee';
    int? deptId = user?['department_id'];
    int? branchId = user?['branch_id'];
    bool isActive = (user?['is_active'] ?? 1) == 1;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => FutureBuilder(
        future: Future.wait([_departments, _branches]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final depts = snapshot.data![0];
          final branches = snapshot.data![1];

          return AlertDialog(
            title: Text(user == null ? 'Add User' : 'Edit User'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: user == null,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      if (user == null)
                        TextFormField(
                          controller: passController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['Employee', 'Agent', 'Lead', 'Manager', 'GlobalAdmin']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => role = v,
                      ),
                      DropdownButtonFormField<int>(
                        value: branchId,
                        decoration: const InputDecoration(labelText: 'Branch'),
                        items: branches
                            .map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name'])))
                            .toList(),
                        onChanged: (v) => branchId = v,
                      ),
                      DropdownButtonFormField<int>(
                        value: deptId,
                        decoration: const InputDecoration(labelText: 'Department'),
                        items: depts
                            .map<DropdownMenuItem<int>>((d) => DropdownMenuItem(value: d['id'], child: Text(d['name'])))
                            .toList(),
                        onChanged: (v) => deptId = v,
                      ),
                      if (user != null)
                        SwitchListTile(
                          title: const Text('Active'),
                          value: isActive,
                          onChanged: (v) => setState(() => isActive = v),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final data = {
                        'email': emailController.text,
                        'password': passController.text,
                        'full_name': nameController.text,
                        'role': role,
                        'branch_id': branchId,
                        'department_id': deptId,
                        'is_active': isActive,
                      };
                      if (user == null) {
                        await _api.createUser(data);
                      } else {
                        await _api.updateUser(user['id'], data);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        _refresh();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: Text(user == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(dynamic user) {
    if (user['role'] == 'GlobalAdmin') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete Global Admin')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['full_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await _api.deleteUser(user['id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  _refresh();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: FutureBuilder<List<dynamic>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final list = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showUserDialog(item),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0056D2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, color: Color(0xFF00D2FF)),
                      ),
                      title: Text(item['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      subtitle: Text('${item['email']} • ${item['role']}', style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent), onPressed: () => _showUserDialog(item)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(item)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
