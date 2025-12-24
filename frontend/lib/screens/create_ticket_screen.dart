import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = ApiService();
  
  bool _isLoading = false;
  bool _isFetchingInitialData = true;

  List<dynamic> _departments = [];
  List<dynamic> _categories = [];
  List<dynamic> _priorities = [];
  List<dynamic> _users = [];
  List<dynamic> _branches = [];

  int? _selectedDepartmentId;
  int? _selectedCategoryId;
  int? _selectedPriorityId;
  int? _selectedAssignedToId;
  int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final depts = await _api.getDepartments();
      final cats = await _api.getCategories();
      final pris = await _api.getPriorities();
      final users = await _api.getUsers();
      final branches = await _api.getBranches();

      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        setState(() {
          _departments = depts;
          _categories = cats;
          _priorities = pris;
          _users = users;
          _branches = branches;

          // Default selection if available
          if (_departments.isNotEmpty) _selectedDepartmentId = _departments.first['id'];
          if (_categories.isNotEmpty) _selectedCategoryId = _categories.first['id'];
          if (_priorities.isNotEmpty) _selectedPriorityId = _priorities.first['id'];
          
          // Set user's branch as default
          _selectedBranchId = auth.user?.branchId;
          if (_selectedBranchId == null && _branches.isNotEmpty) {
              _selectedBranchId = _branches.first['id'];
          }

          _isFetchingInitialData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isFetchingInitialData = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
        final token = await _api.getToken();
        
        final response = await http.post(
            Uri.parse('${ApiService.baseUrl}/tickets'),
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token'
            },
            body: jsonEncode({
                'subject': _subjectController.text.trim(),
                'description': _descriptionController.text.trim(),
                'priority_id': _selectedPriorityId,
                'category_id': _selectedCategoryId,
                'department_id': _selectedDepartmentId,
                'assigned_to': _selectedAssignedToId,
                'branch_id': _selectedBranchId
            })
        );
        
        if (response.statusCode == 201) {
            if (mounted) Navigator.pop(context, true);
        } else {
             throw Exception('Failed to create ticket: ${response.body}');
        }

    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isAdminOrLead = user?.role == 'GlobalAdmin' || user?.role == 'Lead' || user?.role == 'Manager';

    return GlassScaffold(
      appBar: AppBar(title: const Text('Create New Ticket')),
      body: _isFetchingInitialData 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  color: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader('Basic Information'),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _subjectController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Subject', Icons.title),
                            validator: (v) => v!.isEmpty ? 'Please enter a subject' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Description', Icons.description),
                            maxLines: 4,
                            validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                          ),
                          const SizedBox(height: 24),
                          
                          _buildHeader('Classifications'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown<int>(
                                  label: 'Category',
                                  value: _selectedCategoryId,
                                  items: _categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdown<int>(
                                  label: 'Priority',
                                  value: _selectedPriorityId,
                                  items: _priorities.map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['name']))).toList(),
                                  onChanged: (v) => setState(() => _selectedPriorityId = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown<int>(
                            label: 'Target Department',
                            value: _selectedDepartmentId,
                            items: _departments.map((d) => DropdownMenuItem(value: d['id'] as int, child: Text(d['name']))).toList(),
                            onChanged: (v) => setState(() => _selectedDepartmentId = v),
                          ),
                          const SizedBox(height: 24),

                          _buildHeader('Stakeholders'),
                          const SizedBox(height: 16),
                          _buildDropdown<int>(
                            label: 'Branch (Required)',
                            value: _selectedBranchId,
                            items: _branches.map((b) => DropdownMenuItem(value: b['id'] as int, child: Text(b['name']))).toList(),
                            onChanged: (v) => setState(() => _selectedBranchId = v),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: user?.fullName,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white70),
                            decoration: _inputDecoration('Created By', Icons.person_outline, isReadOnly: true),
                          ),
                          if (isAdminOrLead) ...[
                            const SizedBox(height: 16),
                            _buildDropdown<int>(
                              label: 'Assign To (Optional)',
                              value: _selectedAssignedToId,
                              items: _users
                                .where((u) => u['role'] != 'Employee') // Only assign to staff
                                .map((u) => DropdownMenuItem(value: u['id'] as int, child: Text(u['full_name']))).toList(),
                              onChanged: (v) => setState(() => _selectedAssignedToId = v),
                            ),
                          ],
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _isLoading ? null : _submit,
                              icon: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                              label: Text(_isLoading ? 'CREATING...' : 'SUBMIT TICKET', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool isReadOnly = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      filled: isReadOnly,
      fillColor: isReadOnly ? Colors.white.withOpacity(0.05) : null,
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDropdown<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, Icons.list),
      iconEnabledColor: Colors.white70,
    );
  }
}
