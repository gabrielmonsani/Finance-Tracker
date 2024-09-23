import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ihc_project/screens/expense.dart';
import 'package:ihc_project/screens/save_page.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  List<Expense> _expenses = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/expense/get');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _expenses = data
              .map((item) => Expense(
                    id: item['id'],
                    value: item['value'] ?? 0.0,
                    paymentMethod:
                        _translatePaymentMethod(item['paymentMethod'] ?? 'Unknown'),
                    category: item['category'] ?? 'Unknown',
                  ))
              .toList()
              .reversed
              .toList();
        });
      } else {
        _showError('Erro ao carregar despesas: ${response.body}');
      }
    } catch (e) {
      _showError('Erro ao carregar despesas: $e');
    }
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  void _showAddExpenseForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavePage()),
    ).then((_) {
      _loadExpenses(); // Recarrega as despesas após a adição
    });
  }

  String _translatePaymentMethod(String method) {
    switch (method) {
      case 'CASH':
        return 'Dinheiro';
      case 'DEBIT_CARD':
        return 'Cartão de Débito';
      case 'CREDIT_CARD':
        return 'Cartão de Crédito';
      case 'PIX':
        return 'PIX';
      default:
        return 'Outro';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _expenses.isEmpty
            ? const Center(
                child: Text(
                  'Nenhuma despesa criada ainda!',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        '${_expenses[index].paymentMethod}\nR\$ ${_expenses[index].value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black, // Cor padrão do texto
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseForm,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
