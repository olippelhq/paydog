class Transaction {
  final String id;
  final String? fromAccountId;
  final String toAccountId;
  final double amount;
  final String status;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        fromAccountId: json['from_account_id'],
        toAccountId: json['to_account_id'],
        amount: (json['amount'] as num).toDouble(),
        status: json['status'],
        description: json['description'],
        createdAt: DateTime.parse(json['created_at']),
      );
}
