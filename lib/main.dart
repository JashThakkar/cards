import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper.instance;
  await db.database;

  final folders = await db.getFolders();
  if (folders.isEmpty) {
    await db.insertFolder({
      'name': 'Spades',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await db.insertFolder({
      'name': 'Hearts',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await db.insertFolder({
      'name': 'Diamonds',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await db.insertFolder({
      'name': 'Clubs',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Folders',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SuitSelectionPage(),
    );
  }
}

class SuitSelectionPage extends StatelessWidget {
  const SuitSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final suits = [
      {'name': 'Spades', 'icon': '♠️', 'color': Colors.black},
      {'name': 'Hearts', 'icon': '♥️', 'color': Colors.red},
      {'name': 'Diamonds', 'icon': '♦️', 'color': Colors.red},
      {'name': 'Clubs', 'icon': '♣️', 'color': Colors.black},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Select a Suit')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: suits.map((suit) {
          return GestureDetector(
            onTap: () async {
              final db = DatabaseHelper.instance;
              final folders = await db.getFolders();
              final folder = folders.firstWhere(
                (f) => f['name'] == suit['name'],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderPage(folder: folder),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 3),
                  ),
                ],
                border: Border.all(color: suit['color'] as Color, width: 3),
              ),
              child: Center(
                child: Text(
                  suit['icon'] as String,
                  style: TextStyle(fontSize: 64, color: suit['color'] as Color),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FolderPage extends StatefulWidget {
  final Map<String, dynamic> folder;
  const FolderPage({super.key, required this.folder});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<Map<String, dynamic>> cards = [];
  final db = DatabaseHelper.instance;
  final TextEditingController _controller = TextEditingController();

  Future<void> _loadCards() async {
    final data = await db.getCardsByFolder(widget.folder['id']);
    setState(() {
      cards = data;
    });
  }

  Future<void> _addCard(String name) async {
    await db.insertCard({
      'name': name,
      'suit': widget.folder['name'],
      'imageUrl': '',
      'folderId': widget.folder['id'],
      'createdAt': DateTime.now().toIso8601String(),
    });
    _controller.clear();
    await _loadCards();
  }

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.folder['name']} Folder")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter card name (A, 2, 3, J, Q, K...)',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _addCard(_controller.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return ListTile(
                  title: Text(card['name']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await db.deleteCard(card['id']);
                      _loadCards();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
