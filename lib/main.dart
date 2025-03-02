import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shopping List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: const ShoppingListScreen(),
    );
  }
}

class ShoppingItem {
  String name;
  bool isCompleted;

  ShoppingItem({required this.name, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'name': name,
    'isCompleted': isCompleted,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    name: json['name'],
    isCompleted: json['isCompleted'],
  );
}

class SavedList {
  final String date;
  final List<ShoppingItem> items;

  SavedList({required this.date, required this.items});

  Map<String, dynamic> toJson() => {
    'date': date,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory SavedList.fromJson(Map<String, dynamic> json) => SavedList(
    date: json['date'],
    items: (json['items'] as List)
        .map((item) => ShoppingItem.fromJson(item))
        .toList(),
  );
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<ShoppingItem> _items = [];
  final List<SavedList> _savedLists = [];
  final TextEditingController _textController = TextEditingController();
  bool _showCompleted = true;
  final _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadSavedLists();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLists() async {
    final prefs = await _prefs;
    final savedListsJson = prefs.getStringList('savedLists') ?? [];
    setState(() {
      _savedLists.clear();
      _savedLists.addAll(
        savedListsJson
            .map((json) => SavedList.fromJson(jsonDecode(json)))
            .toList(),
      );
    });
  }

  Future<void> _saveCurrentList() async {
    if (_items.isEmpty) return;

    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final newList = SavedList(date: date, items: List.from(_items));
    
    final prefs = await _prefs;
    final savedListsJson = _savedLists
        .map((list) => jsonEncode(list.toJson()))
        .toList();
    savedListsJson.add(jsonEncode(newList.toJson()));
    
    await prefs.setStringList('savedLists', savedListsJson);
    
    setState(() {
      _savedLists.add(newList);
      _items.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ القائمة بتاريخ $date'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _items.add(ShoppingItem(name: name.trim()));
    });
    _textController.clear();
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index].isCompleted = !_items[index].isCompleted;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _processClipboardText() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final lines = clipboardData!.text!.split(RegExp(r'[\n\r]+'));
      setState(() {
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            _items.add(ShoppingItem(name: line.trim()));
          }
        }
      });
    }
  }

  void _showSavedLists() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'القوائم المحفوظة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _savedLists.length,
                itemBuilder: (context, index) {
                  final list = _savedLists[_savedLists.length - 1 - index];
                  final completedItems = list.items.where((item) => item.isCompleted).length;
                  return Card(
                    child: ListTile(
                      title: Text(
                        'قائمة ${list.date}',
                        textAlign: TextAlign.right,
                      ),
                      subtitle: Text(
                        'العناصر: ${list.items.length} (تم شراء $completedItems)',
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.shopping_cart),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _showCompleted 
        ? _items 
        : _items.where((item) => !item.isCompleted).toList();

    final completedCount = _items.where((item) => item.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة مشترياتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showSavedLists,
            tooltip: 'القوائم المحفوظة',
          ),
          IconButton(
            icon: Icon(_showCompleted ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: 'إظهار/إخفاء العناصر المكتملة',
          ),
          IconButton(
            icon: const Icon(Icons.paste),
            onPressed: _processClipboardText,
            tooltip: 'لصق من الحافظة',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'أضف عنصراً جديداً',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.add_shopping_cart),
                        ),
                        textAlign: TextAlign.right,
                        onSubmitted: _addItem,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => _addItem(_textController.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (_items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تم شراء $completedCount من ${_items.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ القائمة'),
                        onPressed: _saveCurrentList,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'قائمة المشتريات فارغة',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'أضف عناصر جديدة أو الصق قائمة من الواتساب',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: displayedItems.length,
                    onReorderStart: (index) {
                      FocusScope.of(context).unfocus();
                    },
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _items.removeAt(oldIndex);
                        _items.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = displayedItems[index];
                      return Dismissible(
                        key: Key('item_${item.name}_$index'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeItem(index),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              item.name,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            leading: Checkbox(
                              value: item.isCompleted,
                              onChanged: (_) => _toggleItem(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'تم تطوير هذا التطبيق من قبل محمد فياض',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
