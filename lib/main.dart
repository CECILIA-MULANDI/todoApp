import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo Demo',
      theme: ThemeData(
        // tested with just a hot reload.
        useMaterial3: true,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController todoController = TextEditingController();
  bool completed = false;
  List<TodoItem> todoItems = [];
  //read from the database
  Future<void> getTodo() async {
    final response =
        await http.get(Uri.parse("http://localhost:8000/api/todo"));
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final items = (jsonData as List)
          .map((itemData) => TodoItem.fromJson(itemData))
          .toList();
      setState(() {
        todoItems = items;
      });
    } else {
      print("nothing was fetched");
      onError?.call("Failed to fetch");
    }
  }

//post to the database
  Future<void> addTodo() async {
    String title = todoController.text;

    final response = await http.post(
      Uri.parse("http://localhost:8000/api/todo"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'description': '',
        'completed': false,
      }),
    );
    if (response.statusCode == 201) {
      print("Todo item added");
    } else {
      onError?.call('Todo item was not added');
    }
  }

  // put to db
  Future<void> updateTodo(String id, bool completed) async {
    final response = await http.put(
      Uri.parse("http://localhost:8000/api/todo/$id"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'completed': completed,
      }),
    );
    if (response.statusCode == 200) {
      print("Todo item updated");
    } else {
      onError?.call('Failed to update todo item');
    }
  }

  void Function(String message)? onError;
  @override
  void initState() {
    super.initState();
    getTodo(); // Fetch the todo items when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Todo App",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: todoItems.length,
                itemBuilder: (context, index) {
                  final item = todoItems[index];
                  return ListTile(
                    title: Text(
                      item.title,
                      style: TextStyle(
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none),
                    ),
                    subtitle: Text(
                      item.description,
                      style: TextStyle(
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none),
                    ),
                    leading: Checkbox(
                      value: item.completed,
                      onChanged: (bool? value) {
                        setState(() {
                          item.completed = value ?? false;
                          updateTodo(item.id, item.completed);
                        });
                      },
                    ),
                  );
                }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextField(
                    controller: todoController,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter a todo item',
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: FractionalOffset.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                if (todoController.text.isNotEmpty) {
                  addTodo();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.white,
                      content: Container(
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20)),
                        height: 90,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Text(
                            "The Todo field must be added",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )));
                }
              },
              child: Icon(Icons.add),
            ),
          )
        ],
      ),
    );
  }
}

// Model class for TodoItem
class TodoItem {
  final String id;
  final String title;
  final String description;
  bool completed;

  TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}
