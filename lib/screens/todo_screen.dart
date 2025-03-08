import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:my_amplify_app/models/Todo.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  Future<void> _refreshTodos() async {
    try {
      final request = ModelQueries.list(Todo.classType);
      final response = await Amplify.API.query(request: request).response;

      final todos = response.data?.items;
      if (response.hasErrors) {
        safePrint('errors: ${response.errors}');
        return;
      }
      setState(() {
        _todos = todos!.whereType<Todo>().toList();
      });
    } on ApiException catch (e) {
      safePrint('Query failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Add Random Todo'),
        onPressed: () async {
          final newTodo = Todo(
            id: uuid(),
            content: "Random Todo ${DateTime.now().toIso8601String()}",
            isDone: false,
          );
          final request = ModelMutations.create(newTodo);
          final response = await Amplify.API.mutate(request: request).response;
          if (response.hasErrors) {
            safePrint('Creating Todo failed.');
          } else {
            safePrint('Creating Todo successful.');
          }
          _refreshTodos();
        },
      ),
      body:
          _todos.isEmpty == true
              ? const Center(
                child: Text(
                  "The list is empty.\nAdd some items by clicking the floating action button.",
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  return Dismissible(
                    key: UniqueKey(),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        final request = ModelMutations.delete(todo);
                        final response =
                            await Amplify.API.mutate(request: request).response;
                        if (response.hasErrors) {
                          safePrint('Updating Todo failed. ${response.errors}');
                        } else {
                          safePrint('Updating Todo successful.');
                          await _refreshTodos();
                          return true;
                        }
                      }
                      return false;
                    },
                    child: CheckboxListTile.adaptive(
                      value: todo.isDone,
                      title: Text(todo.content!),
                      onChanged: (isChecked) async {
                        final request = ModelMutations.update(
                          todo.copyWith(isDone: isChecked!),
                        );
                        final response =
                            await Amplify.API.mutate(request: request).response;
                        if (response.hasErrors) {
                          safePrint('Updating Todo failed. ${response.errors}');
                        } else {
                          safePrint('Updating Todo successful.');
                          await _refreshTodos();
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }
}
