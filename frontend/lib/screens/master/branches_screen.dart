import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _branches;
  List<dynamic> _countries = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadCountries();
  }

  void _refresh() {
    setState(() {
      _branches = _api.getBranches();
    });
  }

  Future<void> _loadCountries() async {
      try {
          final list = await _api.getCountries();
          setState(() {
              _countries = list;
          });
      } catch (e) {
          debugPrint('Error loading countries: $e');
      }
  }

  void _showBranchDialog([dynamic branch]) {
    final nameCtrl = TextEditingController(text: branch?['name']);
    final addressCtrl = TextEditingController(text: branch?['address']);
    final personCtrl = TextEditingController(text: branch?['contact_person']);
    final numberCtrl = TextEditingController(text: branch?['contact_number']);
    final emailCtrl = TextEditingController(text: branch?['contact_email']);
    
    int? selectedCountryId = branch?['country_id'];
    if (selectedCountryId == null && _countries.isNotEmpty) {
      selectedCountryId = _countries[0]['id'];
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(branch == null ? 'Add Branch' : 'Edit Branch'),
          content: SizedBox(
             width: 600,
             child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Branch Name', prefixIcon: Icon(Icons.store)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                        value: selectedCountryId,
                        decoration: const InputDecoration(labelText: 'Country/State', prefixIcon: Icon(Icons.public)),
                        items: _countries.map((c) => DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['name']),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedCountryId = v),
                        validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: personCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person Name', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: numberCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Mobile', prefixIcon: Icon(Icons.phone_iphone)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Email ID', prefixIcon: Icon(Icons.email)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
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
                      'name': nameCtrl.text,
                      'country_id': selectedCountryId,
                      'address': addressCtrl.text,
                      'contact_person': personCtrl.text,
                      'contact_number': numberCtrl.text,
                      'contact_email': emailCtrl.text,
                    };
                    if (branch == null) {
                      await _api.createBranch(data);
                    } else {
                      await _api.updateBranch(branch['id'], data);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(branch == null ? 'Branch Created' : 'Branch Updated')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: Text(branch == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(dynamic branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete ${branch['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await _api.deleteBranch(branch['id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch Deleted')));
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
      appBar: AppBar(title: const Text('Manage Branches')),
      body: FutureBuilder<List<dynamic>>(
        future: _branches,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No branches found.'));

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
                  onTap: () => _showBranchDialog(item),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0056D2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_city_outlined, color: Color(0xFF00D2FF)),
                      ),
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      subtitle: Text('${item['country_name']} • ${item['contact_person']}', style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent), onPressed: () => _showBranchDialog(item)),
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
        onPressed: () => _showBranchDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
