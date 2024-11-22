import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';

class TodoListScreen extends StatefulWidget {
  final String groupId;
  final dynamic groupName;
  final groupColor;

  const TodoListScreen({super.key, required this.groupId, required this.groupName, required this.groupColor});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _controller = TextEditingController();
  CollectionReference? _todos;

  @override
  void initState() {
    super.initState();
    _todos = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection("todo");
  }

  void _addTodo() async {
    if (_controller.text.isNotEmpty && _todos != null) {
      await _todos!.add({'task': _controller.text, 'created_at': Timestamp.now()});
      _controller.clear();
    }
  }

  void _removeTodoAtIndex(String docId) async {
    if (_todos != null) {
      await _todos!.doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
             builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Color(0xff212529),
                title: const Text("добавить задачу", style: TextStyle(color: Colors.white),),
                content: Form(child: 
                TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Colors.white),
                      labelText: 'новая задача',
                    ),
                  ),
                ),
                    actions: [
                    Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white,),
                          onPressed: _addTodo,
                      ),
                    ],
                    ),
                  ),
                ],
              );
             });
        },
        child: const Icon(Icons.add, color: Colors.black, size: 28),),
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Color(widget.groupColor as int),
        title: Text(widget.groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _todos?.orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return SwipeActionCell(
                      key: ValueKey(task.id),
                      trailingActions: [
                        SwipeAction(
                          title: "del",
                          onTap: (handler) async {
                            await handler(true); // Закрыть свайп после выполнения
                            _removeTodoAtIndex(task.id);
                          },
                          color: Colors.red,
                        ),
                      ],
                      child: Container(
                      color:const  Color(0xff121212), // Устанавливаем цвет фона
                      child: ListTile(
                        title: Text(
                          task['task'],
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
