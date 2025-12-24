import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _ticket;
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await _api.getTicketHistory(_ticket['id']);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _api.updateTicket(_ticket['id'], {'status': newStatus});
      // Refresh ticket list or just update local state if possible
      // For simplicity, we'll just show success and refresh history
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
        setState(() {
            _ticket['status'] = newStatus;
            _isUpdating = false;
        });
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showReassignDialog() async {
    final users = await _api.getUsers();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reassign Ticket'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                if (user['role'] == 'Employee') return const SizedBox.shrink();
                return ListTile(
                  title: Text(user['full_name']),
                  subtitle: Text(user['role']),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() => _isUpdating = true);
                    try {
                      await _api.updateTicket(_ticket['id'], {'assigned_to': user['id']});
                      if (mounted) {
                        setState(() {
                          _ticket['assigned_to_name'] = user['full_name'];
                          _isUpdating = false;
                        });
                        _fetchHistory();
                      }
                    } catch (e) {
                      if (mounted)  {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                         setState(() => _isUpdating = false);
                      }
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final canManage = user?.role == 'GlobalAdmin' || user?.role == 'Lead' || user?.role == 'Agent' || user?.role == 'Manager' || user?.role == 'BranchManager';

    final created = DateTime.parse(_ticket['created_at']).toLocal();
    final due = _ticket['due_date'] != null ? DateTime.parse(_ticket['due_date']).toLocal() : null;

    return GlassScaffold(
      appBar: AppBar(title: Text('Ticket #${_ticket['id']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(_ticket['subject'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
                        const SizedBox(width: 8),
                        _buildStatusChip(_ticket['status']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _ticket['description'] ?? 'No description',
                      style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Grid
            const Text('DETAILS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            _infoGrid([
              _infoItem('Branch', _ticket['branch_name'] ?? 'N/A', Icons.location_on_outlined),
              _infoItem('Department', _ticket['department_name'] ?? 'N/A', Icons.business_outlined),
              _infoItem('Category', _ticket['category_name'] ?? 'N/A', Icons.category_outlined),
              _infoItem('Priority', _ticket['priority_name'] ?? 'N/A', Icons.priority_high_rounded),
              _infoItem('Requester', _ticket['requester_name'] ?? 'N/A', Icons.person_outline),
              _infoItem('Assigned', _ticket['assigned_to_name'] ?? 'Unassigned', Icons.assignment_ind_outlined),
              _infoItem('Created', DateFormat('MMM dd, yyyy').format(created), Icons.calendar_today_outlined),
              if (due != null) _infoItem('Due Date', DateFormat('MMM dd, yyyy').format(due), Icons.timer_outlined),
            ]),
            const SizedBox(height: 32),

            // Actions
            if (canManage) ...[
                const Text('ACTIONS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'Change Status',
                        icon: Icons.edit_notifications,
                        onPressed: () => _showStatusPicker(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        label: 'Reassign',
                        icon: Icons.person_add,
                        onPressed: _showReassignDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
            ],

            // History Section
            const Text('TICKET HISTORY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            _isLoadingHistory 
                ? const Center(child: CircularProgressIndicator(color: Colors.white30))
                : _history.isEmpty 
                    ? const Text('No history available.', style: TextStyle(color: Colors.white38))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final h = _history[index];
                          final time = DateTime.parse(h['timestamp']).toLocal();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D2FF).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history_rounded, color: Color(0xFF00D2FF), size: 18),
                              ),
                              title: Text('${h['field_changed']} → ${h['new_value']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              subtitle: Text('By ${h['changed_by_name']} • ${DateFormat('MMM dd, HH:mm').format(time)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final statuses = ['New', 'Open', 'In Progress', 'On Hold', 'Resolved', 'Closed', 'Reopened'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(color: Colors.white10),
              ...statuses.map((s) => ListTile(
                title: Text(s, style: const TextStyle(color: Colors.white)),
                leading: _buildStatusChip(s),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(s);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New': return const Color(0xFF00D2FF);
      case 'Open': return Colors.blueAccent;
      case 'In Progress': return Colors.orangeAccent;
      case 'Resolved': return Colors.greenAccent;
      case 'Closed': return Colors.grey;
      case 'On Hold': return Colors.purpleAccent;
      case 'Reopened': return Colors.redAccent;
      default: return Colors.white;
    }
  }

  Widget _infoGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 3.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00D2FF).withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return FilledButton.icon(
      onPressed: _isUpdating ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
    );
  }
}
