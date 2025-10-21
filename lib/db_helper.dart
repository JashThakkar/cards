import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "CardsDatabase.db";
  static const _databaseVersion = 1;

  static const folderTable = 'folders';
  static const cardTable = 'cards';

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $folderTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        previewImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $cardTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT,
        imageBytes TEXT,
        folderId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (folderId) REFERENCES $folderTable (id) ON DELETE CASCADE
      )
    ''');
  }

  // Folder Methods
  Future<int> insertFolder(Map<String, dynamic> folder) async {
    Database db = await database;
    return await db.insert(folderTable, folder);
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    Database db = await database;
    return await db.query(folderTable);
  }

  // Card Methods
  Future<int> insertCard(Map<String, dynamic> card) async {
    Database db = await database;
    return await db.insert(cardTable, card);
  }

  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    Database db = await database;
    return await db.query(cardTable, where: 'folderId = ?', whereArgs: [folderId]);
  }

  Future<int> deleteCard(int id) async {
    Database db = await database;
    return await db.delete(cardTable, where: 'id = ?', whereArgs: [id]);
  }
}
