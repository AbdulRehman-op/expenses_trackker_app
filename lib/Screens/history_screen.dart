import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _getHistoryExpenses();
  }

  // Stream for PAST EXPENSES ONLY (Before today's 12:00 AM)
  Stream<List<Map<String, dynamic>>> _getHistoryExpenses() {
    final userId = supabase.auth.currentUser?.id;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('created_at', ascending: false)
        .map((list) {
      
      return list.where((item) {
        if (item['created_at'] == null) return false;
        final createdAt = DateTime.parse(item['created_at']).toLocal();
        return createdAt.isBefore(startOfToday);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Past Expenses History',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _historyStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading history: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    );
                  }

                  final historyList = snapshot.data ?? [];

                  if (historyList.isEmpty) {
                    return Center(
                      child: Text(
                        'No historical records found.',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final item = historyList[index];
                      final date = DateTime.parse(item['created_at']).toLocal();
                      final bool isIncome = item['is_income'] ?? (item['category'].toString().toLowerCase() == 'income');

                      return Card(
                        color: Colors.white.withValues(alpha: 0.05),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                          title: Text(
                            item['title'] ?? 'Expense',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${date.day}/${date.month}/${date.year} • ${item['category'] ?? 'General'}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'} PKR ${item['amount']}',
                            style: GoogleFonts.poppins(
                              color: isIncome ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}