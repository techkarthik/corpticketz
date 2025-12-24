import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/screens/create_ticket_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<dynamic>>(
        future: _tickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final allTickets = snapshot.data ?? [];
          final tickets = allTickets.where((t) => t['status'] != 'Resolved' && t['status'] != 'Closed').toList();

          if (tickets.isEmpty) {
             return const Center(child: Text('No active tickets found. Create one!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final status = ticket['status'] ?? 'New';
              Color statusColor;
              switch (status) {
                case 'Resolved': statusColor = Colors.greenAccent; break;
                case 'In Progress': statusColor = Colors.orangeAccent; break;
                case 'Closed': statusColor = Colors.grey; break;
                default: statusColor = const Color(0xFF00D2FF);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // TODO: Open Ticket Detail
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.5)),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            Text('#${ticket['id']}', style: const TextStyle(color: Colors.white30, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket['subject'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.priority_high, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              'Priority: ${ticket['priority_id'] ?? 'Normal'}',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                          ],
                        ),
                      ],
                    ),
                  ),
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
}
