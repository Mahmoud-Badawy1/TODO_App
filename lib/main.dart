// ignore_for_file: deprecated_member_use
import 'db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodoItem {
  int? id;
  String title;
  bool isDone;

  TodoItem({this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'isDone': isDone ? 1 : 0,
    };

    // Do not include 'id' in the map if it's null
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  static TodoItem fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
    );
  }
}

class TodoListManager with ChangeNotifier {
  final List<TodoItem> _todoList = [];
   final List<String> _searchHistory = [];

  TodoListManager() {
     loadTodos();
   }
  List<TodoItem> get todoList => _todoList;
  List<String> get searchHistory => _searchHistory;
  
  // Method to load todos from the database
  void loadTodos() async {
    List<TodoItem> todoItems = await DatabaseProvider.dbProvider.getTodoItems();
    _todoList.clear();
    _todoList.addAll(todoItems);
    notifyListeners();
  }
  
  void addItem(TodoItem item) async {
    // Add to the in-memory list
    _todoList.add(item);
    notifyListeners();

    // Save the new item to the database
    await DatabaseProvider.dbProvider.insertTodoItem(item);
  }

  void removeItem(int item) async {
    _todoList.removeAt(item);
    notifyListeners();

     // delete the item from the database
    await DatabaseProvider.dbProvider.deleteTodoItem(item);
  }

  void toggleDone(int index) async {
  // Get the TodoItem at the specified index
  TodoItem item = _todoList[index];

  // Toggle the isDone status
  item.isDone = !item.isDone;
  notifyListeners();

  // Update the item in the database
  await DatabaseProvider.dbProvider.updateTodoItem(item);
}


  void addToSearchHistory(String searchItem) async {
    _searchHistory.add(searchItem);
    notifyListeners();

    // Save the search term to the database
    await DatabaseProvider.dbProvider.addSearchTerm(searchItem);
  }

  // Clear search history and clear from database
  void clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();

    // Clear the search history from the database
    await DatabaseProvider.dbProvider.clearSearchHistory();
  }

  void loadSearchHistory() async {
  // Retrieve search history from database
  // Assuming you have a method in DatabaseProvider to get all search terms
  List<String> history = await DatabaseProvider.dbProvider.getSearchHistory();
  _searchHistory.addAll(history);
  notifyListeners();
}
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TodoListManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ' To-Do pp with Provider',
      theme: ThemeData(
        // Define the default brightness and colors.
        primaryColor: const Color.fromARGB(255, 10, 30, 40),

        accentColor: const Color.fromARGB(255, 0, 0, 0),

        // Define the default font family.
        fontFamily: 'Georgia',
      ),
      home: const TodoApp(),
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  TodoAppState createState() => TodoAppState();
}

class TodoAppState extends State<TodoApp> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _filter = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do App'),
        backgroundColor: Theme.of(context)
            .primaryColor, // Use the primaryColor defined in the theme
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Search History'),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 200.0, // Set the height of the dialog
                      child: Consumer<TodoListManager>(
                        builder: (context, manager, child) {
                          return ListView(
                            children: manager.searchHistory
                                .map((searchTerm) => ListTile(
                                      title: Text(searchTerm),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Clear History'),
                        onPressed: () {
                          Provider.of<TodoListManager>(context, listen: false)
                              .clearSearchHistory();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Set up a search field in a dialog
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Search To-Do'),
                    content: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter search term...',
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Search"),
                        onPressed: () {
                          var manager = Provider.of<TodoListManager>(context,
                              listen: false);
                          manager.addToSearchHistory(_searchController.text);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(
            255, 6, 156, 215), // Set the background color for the body
        child: Consumer<TodoListManager>(
          builder: (context, manager, child) {
            var todos = manager.todoList;
            if (_filter.isNotEmpty) {
              todos = todos
                  .where((todo) =>
                      todo.title.toLowerCase().contains(_filter.toLowerCase()))
                  .toList();
            }
            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                var todo = todos[index];
                return Dismissible(
                  key: Key(todo.title),
                  onDismissed: (direction) {
                    manager.removeItem(index);
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration:
                            todo.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: todo.isDone,
                          onChanged: (bool? value) {
                            manager.toggleDone(index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            manager.removeItem(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TextEditingController textFieldController = TextEditingController();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Add a new Todo"),
                content: TextField(
                  controller: textFieldController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter something to do...',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("Add"),
                    onPressed: () {
  if (textFieldController.text.isNotEmpty) {
    var manager = Provider.of<TodoListManager>(context, listen: false);
    // Create a new TodoItem without specifying the id
    manager.addItem(TodoItem(title: textFieldController.text));
    Navigator.of(context).pop();
  }
}
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Theme.of(context).accentColor,
        child:
            const Icon(Icons.add), // Use the accentColor defined in the theme
      ),
    );
  }
}
