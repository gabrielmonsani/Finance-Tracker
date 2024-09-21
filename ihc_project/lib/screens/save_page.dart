import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavePage extends StatefulWidget {
  const SavePage({super.key});

  @override
  _SavePageState createState() => _SavePageState();
}

class _SavePageState extends State<SavePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  List<String> _categories = [];

  final storage = FlutterSecureStorage();

  final Map<String, Icon> _paymentMethodIcons = {
    'credit_card': Icon(Icons.credit_card, color: Colors.green),
    'debit_card': Icon(Icons.credit_card, color: Colors.green),
    'pix': Icon(Icons.pix, color: Colors.green),
    'cash': Icon(Icons.money, color: Colors.green),
  };

  final Map<String, String> _paymentMethodLabels = {
    'credit_card': 'Cartão de Crédito',
    'debit_card': 'Cartão de Débito',
    'pix': 'PIX',
    'cash': 'Dinheiro',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final token = await _getToken();
      final url =
          Uri.parse('https://finance-tracker-sgyh.onrender.com/category/get');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categories = data['categories'];

        setState(() {
          _categories =
              categories.map<String>((item) => item['name'] as String).toList();
        });
      } else {
        print('Erro ao carregar categorias: ${response.body}');
      }
    } catch (e) {
      print('Erro ao carregar categorias: $e');
    }
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      double amount = double.parse(_amountController.text);

      // Corpo da requisição
      final body = json.encode({
        'value': amount,
        'paymentMethod': _selectedPaymentMethod == 'credit_card'
            ? 'CREDIT_CARD'
            : _selectedPaymentMethod == 'debit_card'
                ? 'DEBIT_CARD'
                : _selectedPaymentMethod == 'pix'
                    ? 'PIX'
                    : 'CASH',
        'category': {
          'id': _categories.indexOf(_selectedCategory!) +
              1 // Assumindo que o ID é baseado na posição
        }
      });

      final token = await _getToken();
      if (token == null) {
        print('Token não encontrado. Faça o login novamente.');
        return;
      }

      final url = Uri.parse(
          'https://finance-tracker-sgyh.onrender.com/expense/register');
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      // Enviar a requisição POST
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gasto de R\$${amount.toStringAsFixed(2)} salvo!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.greenAccent.shade700,
          ),
        );

        // Limpar campos
        _amountController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedPaymentMethod = null;
        });
      } else {
        // Tratamento de erros
        print(
            'Erro ao salvar despesa: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar despesa: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Escolha uma categoria'),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  labelStyle: TextStyle(color: Colors.green.shade600),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, escolha uma categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                hint: const Text('Escolha o método de pagamento'),
                items: _paymentMethodIcons.keys.map((key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Row(
                      children: [
                        _paymentMethodIcons[key]!,
                        const SizedBox(width: 10),
                        Text(_paymentMethodLabels[key]!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Método de Pagamento',
                  labelStyle: TextStyle(color: Colors.green.shade600),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, escolha o método de pagamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: TextStyle(color: Colors.green.shade600),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Insira um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 60),
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
