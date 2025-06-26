import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class Habit {
  String title;
  bool isDone;

  Habit(this.title, {this.isDone = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isDone': isDone,
  };

  factory Habit.fromJson(Map<String, dynamic> json) =>
      Habit(json['title'], isDone: json['isDone']);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Habits',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: HomeScreen(onToggleTheme: toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('habits');
    if (data != null) {
      List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        habits = jsonList.map((e) => Habit.fromJson(e)).toList();
      });
    }
  }

  void _saveHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList =
    habits.map((e) => e.toJson()).toList();
    prefs.setString('habits', jsonEncode(jsonList));
  }

  void _addHabit(String title) {
    setState(() {
      habits.add(Habit(title));
    });
    _saveHabits();
  }

  void _toggleDone(int index) {
    setState(() {
      habits[index].isDone = !habits[index].isDone;
    });
    _saveHabits();
  }

  void _deleteHabit(int index) {
    setState(() {
      habits.removeAt(index);
    });
    _saveHabits();
  }

  void _showAddDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter a certain activity"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addHabit(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text("Enter"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final TextEditingController controller =
    TextEditingController(text: habits[index].title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Habit"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  habits[index].title = controller.text.trim();
                });
                _saveHabits();
              }
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this habit?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                _deleteHabit(index);
                Navigator.of(context).pop();
              },
              child: const Text("Confirm")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habits'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: habits.isEmpty
            ? const Center(child: Text("No habits yet. Add some!"))
            : ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: habit.isDone,
                  onChanged: (_) => _toggleDone(index),
                ),
                title: Text(
                  habit.title,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: habit.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _showEditDialog(index),
                    ),
                    IconButton(
                      icon:
                      const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
