import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ihc_project/screens/expense_page.dart';
import 'package:ihc_project/screens/account_page.dart';
import 'package:ihc_project/screens/categories_page.dart';
import 'package:ihc_project/screens/login_page.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardPage extends StatefulWidget {
  final String token;

  const DashboardPage({super.key, required this.token});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = '';
  String userId = ''; // Adicione a variável para armazenar o userId
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> categoriesData = [];
  double totalValue = 0;
  double rotationAngle = 0;// Para animação de rotação

  // Lista de 25 tons de verde
  final List<Color> categoryColors = [
    Color(0xFF81C784),
    Color(0xFF66BB6A),
    Color(0xFF4CAF50),
    Color(0xFF388E3C),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
    Color(0xFFA5D6A7),
    Color(0xFF43A047),
    Color(0xFF76D275),
    Color(0xFF4C9A2A),
    Color(0xFF7CB342),
    Color(0xFF8BC34A),
    Color(0xFF9CCC65),
    Color(0xFFAED581),
    Color(0xFFC5E1A5),
    Color(0xFFCDDC39),
    Color(0xFFD4E157),
    Color(0xFFE6EE9C),
    Color(0xFF33691E),
    Color(0xFF558B2F),
    Color(0xFF689F38),
    Color(0xFF8BC34A),
    Color(0xFFAED581),
    Color(0xFF558B2F),
  ];

 @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchCategoryValues();
  }

  Future<void> _loadUserName() async {
    try {
      Map<String, dynamic> tokenData = JwtDecoder.decode(widget.token);
      String email = tokenData['sub'] ?? '';

      if (email.isNotEmpty) {
        final url = Uri.parse(
            'https://finance-tracker-sgyh.onrender.com/user/get/$email');
        final headers = {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        };

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            userName = data['name']?.split(' ')[0] ?? '';
          });
        } else {
          print('Erro ao carregar dados do usuário: ${response.body}');
        }
      } else {
        print('Email não encontrado no token.');
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    }
  }

   Future<List<PieChartSectionData>> _fetchCategoryValues() async {
  try {
    // Decodifica o token para extrair o userId e o email
    Map<String, dynamic> tokenData = JwtDecoder.decode(widget.token);
    final userId = tokenData['userId'] as int; // Converta o userId para int
    final email = tokenData ['email']; // Supondo que o email esteja armazenado no token

    final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/category/get/$userId');
    print('reuqisicao mandada com id $userId');
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${widget.token}",
    };

    final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<PieChartSectionData> sections = [];
        categoriesData = [];

        totalValue = 0; // Resetar totalValue

        // Calcular o total
        for (var category in data['categories']) {
          totalValue += category['value'];
        }

        if (totalValue == 0) {
          // Se não houver categorias, retorna uma seção cinza
          sections.add(
            PieChartSectionData(
              color: Colors.grey,
              value: 0,
              title: '0%', // Exibir 0%
              radius: 100,
            ),
          );
        } else {
          for (var category in data['categories']) {
            double value = category['value'];
            String name = category['name'];
            Color color =
                categoryColors[sections.length % categoryColors.length];

            double percentage = (value / totalValue) * 100;

            sections.add(
              PieChartSectionData(
                color: color,
                value: value,
                title:
                    '${percentage.toStringAsFixed(2)}%', // Exibir a porcentagem com 2 casas decimais
                radius: 100,
              ),
            );

            categoriesData.add({
              'name': name,
              'value': value,
              'color': color,
            });
          }
        }

        return sections;
      } else {
        print('Erro ao carregar dados das categorias: ${response.body}');
        throw Exception('Erro ao carregar dados');
      }
    } catch (e) {
      print('Erro ao carregar dados das categorias: $e');
      throw e;
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair da Conta'),
          content:
              const Text('Você tem certeza de que deseja sair da sua conta?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sair'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await storage.delete(key: 'auth_token');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _refreshPage() async {
    await _loadUserName(); // Recarrega o nome do usuário
    await _fetchCategoryValues(); // Recarrega os valores das categorias
    setState(() {
      rotationAngle += 360; // Atualiza o ângulo de rotação
    }); // Atualiza a interface da tela
  }

  Widget _buildCircularIcon(IconData icon) {
    return GestureDetector(
      onTap: () {
        // Abre a Drawer ao clicar no ícone
        Scaffold.of(context).openEndDrawer();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            _buildCircularIcon(Icons.account_balance_wallet), // Ícone da carteira
            const SizedBox(width: 10),
            const Text(
              'FinanceTracker',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Ícone de atualização
            onPressed: _refreshPage, // Atualiza a página ao clicar
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu), // Ícone de menu
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Abre a Drawer ao clicar
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.person, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    userName.isEmpty ? 'Carregando...' : 'Olá, ${userName}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: _buildCircularIcon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: _buildCircularIcon(Icons.category),
              title: const Text('Categorias'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesPage(
                            token: '',
                          )),
                );
              },
            ),
            ListTile(
              leading: _buildCircularIcon(Icons.attach_money),
              title: const Text('Despesas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ExpensePage(
                            token: '',
                          )),
                );
              },
            ),
            ListTile(
              leading: _buildCircularIcon(Icons.person),
              title: const Text('Minha Conta'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountPage(
                      userName: userName,
                      userEmail: '',
                      token: '',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout), // Mantenha o ícone aqui sem círculo
              title: const Text('Sair'),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<PieChartSectionData>>(
                future: _fetchCategoryValues(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar os dados.'));
                  }

                  // Exibe a mensagem quando não há categorias
                  if (categoriesData.isEmpty) {
                    return const Center(
                      child: Text(
                        'Você ainda não possui nenhuma despesa lançada!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: rotationAngle - 360,
                          end: rotationAngle,
                        ),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Container(
                            height: 300, // Defina uma altura específica para o gráfico
                            child: PieChart(
                              PieChartData(
                                sections: snapshot.data!,
                                centerSpaceRadius: 50,
                                sectionsSpace: 2,
                                startDegreeOffset: value,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 60),
                      Expanded(
                        child: ListView.builder(
                          itemCount: categoriesData.length,
                          itemBuilder: (context, index) {
                            var category = categoriesData[index];
                            return Card(
                              color: category['color'],
                              child: ListTile(
                                title: Text(category['name']),
                                trailing: Text(
                                  'R\$ ${category['value'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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