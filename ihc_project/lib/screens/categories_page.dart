import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> _categories = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/category/get');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categories = data['categories'];

        setState(() {
          _categories = List<Category>.from(categories.map((item) => Category.fromJson(item)));
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

  void _addCategory(String category) async {
    if (_categories.any((c) => c.name.toLowerCase() == category.toLowerCase())) {
      _showConfirmationMessage('O nome da categoria já está em uso!');
      return;
    }

    try {
      final token = await _getToken();
      final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/category/create');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = json.encode({"name": category});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        await _loadCategories();
        _showConfirmationMessage('Categoria criada com sucesso!', color: Colors.green);
      } else {
        print('Erro ao adicionar categoria: ${response.body}');
      }
    } catch (e) {
      print('Erro ao adicionar categoria: $e');
    }
  }

  void _editCategory(int index) {
    final currentCategory = _categories[index];
    final controller = TextEditingController(text: currentCategory.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Categoria'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Digite o novo nome da categoria',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final newCategory = controller.text.trim();
                if (newCategory.isNotEmpty && newCategory != currentCategory.name) {
                  _updateCategory(currentCategory.id, newCategory, index);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCategory(int id, String newCategory, int index) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/category/update/$id');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = json.encode({"name": newCategory});

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          _categories[index].name = newCategory;
        });
      } else {
        print('Erro ao atualizar categoria: ${response.body}');
      }
    } catch (e) {
      print('Erro ao atualizar categoria: $e');
    }
  }

  void _deleteCategory(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Categoria'),
          content: const Text('Tem certeza de que deseja excluir esta categoria?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _removeCategory(_categories[index].id, index);
                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeCategory(int id, int index) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('https://finance-tracker-sgyh.onrender.com/category/delete/$id');

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 204) {
        setState(() {
          _categories.removeAt(index);
        });
        _showConfirmationMessage('Categoria excluída com sucesso!', color: Colors.red);
      } else {
        print('Erro ao remover categoria: ${response.body}');
      }
    } catch (e) {
      print('Erro ao remover categoria: $e');
    }
  }

  void _showConfirmationMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _categories.isEmpty
            ? const Center(
                child: Text(
                  'Nenhuma categoria criada ainda!',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: CategoryTile(
                            title: _categories[index].name,
                            onEdit: () => _editCategory(index),
                            onDelete: () => _deleteCategory(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Nova Categoria'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Digite o nome da nova categoria',
                  ),
                  autofocus: true,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      final newCategory = controller.text.trim();
                      if (newCategory.isNotEmpty) {
                        _addCategory(newCategory);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Category {
  final int id;
  String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.title,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
