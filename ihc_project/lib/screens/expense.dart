class Expense {
  final int id; // Campo ID
  final double value;
  final String paymentMethod;
  final String category; // Adicione a categoria, se necessário

  Expense({required this.id, required this.value, required this.paymentMethod, required this.category});
}