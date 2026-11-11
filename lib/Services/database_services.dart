import 'dart:convert';

import 'package:expenses_tracker/Model/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseServices {

  static const String _key = 'transactions_list ' ;

  Future<void> saveTransaction (List<TransactionModel> list ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = list.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<List<TransactionModel>> loadTransactions() async{
    final prefs = await SharedPreferences.getInstance();
    List<String>?  jsonList = prefs.getStringList(_key);

    if(jsonList == null ) return [];
    return jsonList.map((item) => TransactionModel.fromJson(jsonDecode(item))).toList();
  }
}