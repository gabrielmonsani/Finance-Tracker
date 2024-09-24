import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ihc_project/screens/categories_page.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'expense_page.dart';

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
  List<Map<String, dynamic>> _categories = []; // Mudando para uma lista de mapas

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

      if (token == null) {
        print('Token não encontrado.');
        return; // Se o token não estiver presente, saia do método
      }

      // Decodifica o token para extrair os dados
      Map<String, dynamic> tokenData = JwtDecoder.decode(token);
      final userId = tokenData['userId']; // Supondo que userId esteja no token

      // Adiciona o userId na URL
      final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/category/get/$userId');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categories = data['categories'];

        setState(() {
          // Armazenando categorias como uma lista de Map
          _categories = List<Map<String, dynamic>>.from(categories.map((item) {
            return {
              'id': item['id'], // Adicionando ID
              'name': item['name'], // Adicionando nome
            };
          }));
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

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      double amount = double.parse(_amountController.text);

      // Obter o ID da categoria selecionada
      final selectedCategory = _categories.firstWhere(
          (category) => category['name'] == _selectedCategory,
          orElse: () => {'id': null}); // Caso não encontre, retorna um mapa vazio

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
          'id': selectedCategory['id'] // Agora pegamos o ID correto
        }
      });

      final token = await _getToken();
      if (token == null) {
        print('Token não encontrado. Faça o login novamente.');
        return;
      }

      // Decodificar o token para obter o userId
      Map<String, dynamic> tokenData = JwtDecoder.decode(token);
      final userId = tokenData['userId']; // Ajuste essa chave conforme a estrutura do seu token

      if (userId == null) {
        print('User ID não encontrado no token.');
        return;
      }

      final url = Uri.parse(
          'https://finance-tracker-sgyh.onrender.com/expense/register/$userId'); // Incluindo o userId na URL
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

        // Redirecionar para a página de despesas
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ExpensePage(token: '')),
        );
      } else {
        // Tratamento de erros
        print('Erro ao salvar despesa! ${response.statusCode} - ${response.body}');
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
        title: const Text('Lançar Gastos'),
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
                    value: category['name'], // Usando o nome da categoria
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade600), // Borda verde
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
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green.shade600),
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
                    return 'Por favor, informe o valor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Salvar Gasto',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}