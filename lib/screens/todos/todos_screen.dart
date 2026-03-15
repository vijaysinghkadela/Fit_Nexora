import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  void _fetchTodos() {
    _future = Supabase.instance.client.from('todos').select();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _fetchTodos();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final todos = snapshot.data!;
          if (todos.isEmpty) {
            return const Center(child: Text('No todos found.'));
          }
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              itemCount: todos.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final todo = todos[index];
                return ListTile(
                  title: Text(todo['name'] ?? ''),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
