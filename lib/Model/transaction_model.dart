class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isIncome;

  TransactionModel(
      {required this.id,
      required this.title,
      required this.category,
      required this.amount,
      required this.date,
      required this.isIncome});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
          id: json['id'],
          title: json['title'],
          category: json['category'],
          amount: (json['amount'] as num).toDouble(),
          date: DateTime.parse(json['date']),
          isIncome: json['isIncome'] ?? false
      );
}
