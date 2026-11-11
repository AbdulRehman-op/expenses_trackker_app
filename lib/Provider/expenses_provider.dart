import 'package:expenses_tracker/Model/transaction_model.dart';
import 'package:expenses_tracker/Services/database_services.dart';
import 'package:flutter/material.dart';

class ExpensesProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];

  final DatabaseServices _services = DatabaseServices();

  List<TransactionModel> get transactions => _transactions;
  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);
  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);
  double get netExpense => totalIncome - totalExpense;

  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.add(transaction);
    await _services.saveTransaction(_transactions);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _services.saveTransaction(_transactions);
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _transactions = await _services.loadTransactions();
    notifyListeners();
  }
}
