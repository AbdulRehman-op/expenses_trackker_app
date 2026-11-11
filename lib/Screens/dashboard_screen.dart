import 'dart:ui';
import 'package:expenses_tracker/Provider/theme_provider.dart';
import 'package:expenses_tracker/Screens/add_expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _transactionStream;
  // Local set to track IDs being deleted for "Optimistic UI"
  final Set<String> _optimisticDeletedIds = {};

  @override
  void initState() {
    super.initState();
    _transactionStream = _getTransactions();
  }

  // Supabase Stream to get Realtime Data
  Stream<List<Map<String, dynamic>>> _getTransactions() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // Delete Transaction
  Future<void> _deleteExpense(String id) async {
    // 1. Update UI immediately
    setState(() {
      _optimisticDeletedIds.add(id);
    });

    try {
      // 2. Perform background delete
      await supabase.from('expenses').delete().eq('id', id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted!'), 
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // 3. Rollback if failed
      setState(() {
        _optimisticDeletedIds.remove(id);
      });
      debugPrint('Delete Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E004E), Color(0xFF4D1252), Color(0xFF8C256B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'DashBoard',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                themeProvider.toggleTheme(!isDark);
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _transactionStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final allItems = snapshot.data ?? [];
            final items = allItems.where((item) => !_optimisticDeletedIds.contains(item['id'])).toList();

            // Calculations
            double totalIncome = 0.0;
            double totalExpense = 0.0;

            for (var item in items) {
              double amt = double.tryParse(item['amount'].toString()) ?? 0.0;
              bool isIncome = item['is_income'] ?? (item['category'].toString().toLowerCase() == 'income');
              if (isIncome) {
                totalIncome += amt;
              } else {
                totalExpense += amt;
              }
            }

            double totalBalance = totalIncome - totalExpense;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),


                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Balance',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'PKR ${totalBalance.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Income
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Income', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                        Text('PKR ${totalIncome.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                                // Expense
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.arrow_upward, color: Colors.redAccent, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Expense', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                        Text('PKR ${totalExpense.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Header: Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${items.length} items',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 2. Transactions List
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                      child: Text(
                        'No transactions yet!',
                        style: GoogleFonts.poppins(color: Colors.white60),
                      ),
                    )
                        : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final bool isIncome = item['is_income'] ?? (item['category'].toString().toLowerCase() == 'income');
                        final DateTime date = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white12,
                              child: Icon(
                                isIncome ? Icons.check_circle_outline : Icons.shopping_bag_outlined,
                                color: isIncome ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            title: Text(
                              item['title'] ?? 'Item',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy').format(date),
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} PKR ${item['amount']}',
                                  style: GoogleFonts.poppins(
                                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                                  onPressed: () => _deleteExpense(item['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF5B6BFE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExpensesScreen()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}