import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  String? _selectedBranch;
  String? _selectedDept;
  String? _selectedCategory;
  String? _selectedStatus;

  List<dynamic> _branches = [];
  List<dynamic> _departments = [];
  List<dynamic> _categories = [];
  List<dynamic> _users = [];
  String? _selectedUser;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _api.getBranches(),
        _api.getDepartments(),
        _api.getCategories(),
        _api.getUsers(),
        _fetchReport(),
      ]);
      if (mounted) {
        setState(() {
          _branches = results[0] as List<dynamic>;
          _departments = results[1] as List<dynamic>;
          _categories = results[2] as List<dynamic>;
          _users = results[3] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchReport() async {
    final filters = <String, String>{};
    if (_selectedBranch != null) filters['branch_id'] = _selectedBranch!;
    if (_selectedDept != null) filters['department_id'] = _selectedDept!;
    if (_selectedCategory != null) filters['category_id'] = _selectedCategory!;
    if (_selectedUser != null) filters['requester_id'] = _selectedUser!;
    if (_selectedStatus != null) filters['status'] = _selectedStatus!;
    if (_startDate != null) filters['startDate'] = _startDate!.toIso8601String().split('T')[0];
    if (_endDate != null) filters['endDate'] = _endDate!.toIso8601String().split('T')[0];

    final data = await _api.getReportSummary(filters);
    if (mounted) {
      setState(() {
        _reportData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildCharts(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildDropdown('Branch', _selectedBranch, _branches, (val) {
                  setState(() => _selectedBranch = val);
                  _fetchReport();
                }),
                _buildDropdown('Department', _selectedDept, _departments, (val) {
                  setState(() => _selectedDept = val);
                  _fetchReport();
                }),
                _buildDropdown('Category', _selectedCategory, _categories, (val) {
                  setState(() => _selectedCategory = val);
                  _fetchReport();
                }),
                _buildDropdown('User', _selectedUser, _users, (val) {
                  setState(() => _selectedUser = val);
                  _fetchReport();
                }, nameKey: 'full_name'),
                _buildStatusDropdown(),
                _buildDatePicker('Start Date', _startDate, (date) {
                  setState(() => _startDate = date);
                  _fetchReport();
                }),
                _buildDatePicker('End Date', _endDate, (date) {
                  setState(() => _endDate = date);
                  _fetchReport();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<dynamic> items, Function(String?) onChanged, {String nameKey = 'name'}) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        dropdownColor: const Color(0xFF101520),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...items.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e[nameKey] ?? e['name'] ?? 'Unknown'))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final statuses = ['New', 'In Progress', 'On Hold', 'Resolved', 'Closed'];
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        decoration: InputDecoration(
          labelText: 'Status',
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        dropdownColor: const Color(0xFF101520),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: (val) {
          setState(() => _selectedStatus = val);
          _fetchReport();
        },
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, Function(DateTime?) onChanged) {
    return SizedBox(
      width: 180,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            value == null ? 'Select Date' : value.toIso8601String().split('T')[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_reportData == null) return const SizedBox();
    final stats = _reportData!['overallStats'];
    return Row(
      children: [
        _buildStatCard('Total', stats['total_tickets'].toString(), Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Open', stats['open_tickets'].toString(), Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard('Resolved', (stats['resolved_tickets'] ?? 0).toString(), Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharts() {
    if (_reportData == null) return const SizedBox();
    return Column(
      children: [
        _buildPieChart('Tickets by Status', _reportData!['statusSummary'], 'status'),
        const SizedBox(height: 24),
        _buildBarChart('Tickets by Category', _reportData!['categorySummary'], 'category_name'),
      ],
    );
  }

  Widget _buildPieChart(String title, List<dynamic> data, String labelKey) {
    if (data.isEmpty) return const SizedBox();
    
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(data.length, (i) {
                    final item = data[i];
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: (item['count'] as num).toDouble(),
                      title: '${item[labelKey]}\n${item['count']}',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String title, List<dynamic> data, String labelKey) {
    if (data.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(data.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (data[i]['count'] as num).toDouble(),
                          color: Colors.blueAccent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const Text('');
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(data[index][labelKey].toString().substring(0, 3), 
                                style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
