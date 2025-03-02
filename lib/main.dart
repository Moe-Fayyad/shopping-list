import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> items = [];
  final TextEditingController textController = TextEditingController();
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    isDark = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة مشترياتي'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                isDark = !isDark;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'أضف عنصراً جديداً',
                      border: OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      setState(() {
                        items.add(ShoppingItem(name: textController.text));
                        textController.clear();
                      });
                    }
                  },
                  child: const Text('إضافة'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData?.text != null) {
                      final lines = clipboardData!.text!.split('\n');
                      setState(() {
                        for (var line in lines) {
                          if (line.trim().isNotEmpty) {
                            items.add(ShoppingItem(name: line.trim()));
                          }
                        }
                      });
                    }
                  },
                  child: const Text('لصق'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                });
              },
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Dismissible(
                  key: Key('${item.name}$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      items.removeAt(index);
                    });
                  },
                  child: ListTile(
                    title: Text(
                      item.name,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Checkbox(
                      value: item.isCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          item.isCompleted = value ?? false;
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              'تم تطوير هذا التطبيق من قبل محمد فياض',
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
