import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart';

class DatabaseProvider {
  static final DatabaseProvider dbProvider = DatabaseProvider();
  late Database _database;

  Future<Database> get database async {
    // ignore: unnecessary_null_comparison
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'todo_list.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE TodoItems(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        isDone INTEGER
      )
    ''');
    
     await db.execute('''
    CREATE TABLE SearchHistory(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      searchTerm TEXT
    )
  ''');
  }

  // Add TodoItem to the database
  Future<int> insertTodoItem(TodoItem todoItem) async {
    final db = await database;
    var result = await db.insert('TodoItems', todoItem.toMap());
    return result;
  }

  // Get all TodoItems from the database
  Future<List<TodoItem>> getTodoItems() async {
    final db = await database;
    var result = await db.query('TodoItems');
    List<TodoItem> todoItems = result.isNotEmpty
        ? result.map((item) => TodoItem.fromMap(item)).toList()
        : [];
    return todoItems;
  }

  // Update a TodoItem
  Future<int> updateTodoItem(TodoItem todoItem) async {
    final db = await database;
    return await db.update('TodoItems', todoItem.toMap(),
        where: 'id = ?', whereArgs: [todoItem.id]);
  }

  // Delete a TodoItem
  Future<int> deleteTodoItem(int id) async {
    final db = await database;
    return await db.delete('TodoItems', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addSearchTerm(String searchTerm) async {
  final db = await database;
  var result = await db.insert('SearchHistory', {'searchTerm': searchTerm});
  return result;
}

// Clear all search terms from the database
Future<int> clearSearchHistory() async {
  final db = await database;
  var result = await db.delete('SearchHistory');
  return result;
}
Future<List<String>> getSearchHistory() async {
    final db = await database;
    var result = await db.query('SearchHistory', orderBy: 'id DESC');

    List<String> searchHistory = [];
    for (var item in result) {
      searchHistory.add(item['searchTerm'] as String);
    }

    return searchHistory;
  }
}


