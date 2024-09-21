import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ihc_project/screens/account_page.dart';
import 'package:ihc_project/screens/categories_page.dart';
import 'package:ihc_project/screens/save_page.dart';
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
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      // Decodificar o token para extrair o email
      Map<String, dynamic> tokenData = JwtDecoder.decode(widget.token);
      String email = tokenData['sub'] ?? '';

      if (email.isNotEmpty) {
        // Fazer a requisição para obter os dados do usuário
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
            userName = data['name'] ?? '';
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
                Navigator.of(context).pop(false); // Retorna falso
              },
            ),
            TextButton(
              child: const Text('Sair'),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna verdadeiro
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Limpar o token armazenado de forma segura
      await storage.delete(key: 'auth_token');

      // Redirecionar para a página de login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (Route<dynamic> route) => false, // Remover todas as rotas anteriores
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 40, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'FinanceTracker',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
                    userName.isEmpty ? 'Carregando...' : userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categorias'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Despesas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Minha Conta'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountPage(
                      userName: userName,
                      userEmail: '', // Ajuste conforme necessário
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
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
            const SizedBox(height: 20),
            Text(
              'Bem-vindo(a), $userName!',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                            color: Colors.blue,
                            value: 40,
                            title: '40%',
                            radius: 100),
                        PieChartSectionData(
                            color: Colors.red,
                            value: 30,
                            title: '30%',
                            radius: 100),
                        PieChartSectionData(
                            color: Colors.green,
                            value: 20,
                            title: '20%',
                            radius: 100),
                        PieChartSectionData(
                            color: Colors.orange,
                            value: 10,
                            title: '10%',
                            radius: 100),
                      ],
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
