import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AccountPage extends StatefulWidget {
  final String userName;

  const AccountPage(
      {super.key, required this.userName, required String userEmail});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final storage = FlutterSecureStorage();
  String userName = '';
  String userEmail = '';
  String accountCreatedAt = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final token = await _getToken();

      if (token == null) {
        print('Token não encontrado.');
        return;
      }

      // Decodificando o token para extrair o email do campo 'sub'
      Map<String, dynamic> tokenData = JwtDecoder.decode(token);
      userEmail = tokenData['sub']; // Usando 'sub' como email

      final url = Uri.parse(
          'https://finance-tracker-sgyh.onrender.com/user/get/$userEmail');
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['name'] ?? widget.userName;
          accountCreatedAt = data['createdAt'] ?? 'N/A';
        });
      } else {
        print('Erro ao carregar dados do usuário: ${response.body}');
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    }
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 200, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              userName.isNotEmpty ? userName : widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Email: $userEmail',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Conta criada em: $accountCreatedAt',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
