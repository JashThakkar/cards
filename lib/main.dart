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
          // show preview image + card count per folder
          final db = DatabaseHelper.instance; 
          return FutureBuilder<Map<String, dynamic>>( 
            future: () async { 
              // find this suit's folder row
              final folders = await db.getFolders();
              final folder = folders.firstWhere((f) => f['name'] == suit['name']);
              final int folderId = folder['id'] as int;
              // get preview image (first card image) + count
              final count = await db.countCardsInFolder(folderId);
              final preview = await db.firstCardImageUrl(folderId);
              return {
                'folder': folder,
                'count': count,
                'preview': preview,
              };
            }(), 
            builder: (context, snap) { 
              Widget content;
              if (!snap.hasData) {
                content = const Center(child: CircularProgressIndicator());
              } else {
                final folder = snap.data!['folder'] as Map<String, dynamic>;
                final count = snap.data!['count'] as int;
                final preview = snap.data!['preview'] as String?;
                content = GestureDetector(
                  onTap: () async {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: (preview != null && preview.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                  child: Image.network(
                                    preview,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    suit['icon'] as String,
                                    style: TextStyle(fontSize: 64, color: suit['color'] as Color),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            folder['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                          child: Text('$count cards'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return content;
            },
          );
           END
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

  Future<void> _updateCard(Map<String, dynamic> card) async {
    final nameCtrl = TextEditingController(text: card['name'] ?? '');
    final suitCtrl = TextEditingController(text: card['suit'] ?? widget.folder['name']);
    final imgCtrl  = TextEditingController(text: card['imageUrl'] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: suitCtrl, decoration: const InputDecoration(labelText: 'Suit')),
            TextField(controller: imgCtrl,  decoration: const InputDecoration(labelText: 'Image URL')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await db.updateCard({
                'id': card['id'],
                'name': nameCtrl.text,
                'suit': suitCtrl.text,
                'imageUrl': imgCtrl.text,
                'folderId': widget.folder['id'],
              });
              if (context.mounted) Navigator.pop(context);
              _loadCards();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(int id) async {
    await db.deleteCard(id);
    _loadCards();
  }
   END

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
            child: GridView.builder(
              padding: const EdgeInsets.all(8), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( 
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final img = (card['imageUrl'] as String?) ?? '';
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: (img.isNotEmpty)
                            ? Image.network(img, fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.image_not_supported)),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          card['name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Update', 
                              icon: const Icon(Icons.edit, size: 20), 
                              onPressed: () => _updateCard(card), 
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteCard(card['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
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
