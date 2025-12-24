import 'package:flutter/material.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/widgets/glass_scaffold.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _tickets;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _tickets = _api.getTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Manage Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _tickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) return const Center(child: Text('No tickets found.'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(ticket['status']).withOpacity(0.2),
                    child: Text(
                      '${ticket['id']}',
                      style: TextStyle(color: _getStatusColor(ticket['status']), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(ticket['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${ticket['branch_name'] ?? 'No Branch'} | Status: ${ticket['status']} | ${ticket['category_name'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ticket['due_date']?.substring(0, 10) ?? '-', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TicketDetailScreen(ticket: ticket)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          );
          if (result == true) {
            _refresh();
          }
        },
        label: const Text('New Ticket'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New': return Colors.blue;
      case 'Open': return Colors.green;
      case 'In Progress': return Colors.orange;
      case 'Resolved': return Colors.teal;
      case 'Closed': return Colors.grey;
      default: return Colors.white;
    }
  }
}
