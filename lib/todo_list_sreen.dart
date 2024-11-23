import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:msh_checkbox/msh_checkbox.dart';

class TodoListScreen extends StatefulWidget {
  final String groupId;
  final dynamic groupName;
  final groupColor;

  const TodoListScreen(
      {super.key,
      required this.groupId,
      required this.groupName,
      required this.groupColor});

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

  void _addTodo() {
    if (_controller.text.isNotEmpty) {
      _todos?.add({
        'task': _controller.text,
        'created_at': Timestamp.now(),
        'is_done': false, // Добавляем поле для состояния чекбокса
      });

      _controller.clear();
    }
  }

  void _removeTodoAtIndex(String docId) async {
    if (_todos != null) {
      await _todos!.doc(docId).delete();
    }
  }

  void _toggleCheckbox(String docId, bool currentState) {
    if (_todos != null) {
      _todos!.doc(docId).update({'is_done': !currentState});
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
                  backgroundColor: const Color(0xff212529),
                  title: const Text(
                    "Добавить задачу",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Form(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(color: Colors.white),
                        labelText: 'Новая задача',
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _addTodo();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              });
        },
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
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
                    final isDone = task['is_done'] as bool;
                    return SwipeActionCell(
                      key: ValueKey(task.id),
                      trailingActions: [
                        SwipeAction(
                          title: "Удалить",
                          onTap: (handler) async {
                            await handler(true);
                            _removeTodoAtIndex(task.id);
                          },
                          color: Colors.red,
                          performsFirstActionWithFullSwipe: true,
                        ),
                      ],
                      child: Container(
                        color: const Color(0xff121212),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 25),
                              child: MSHCheckbox(
                                size: 25,
                                value: isDone, // Значение из Firestore
                                colorConfig: MSHColorConfig.fromCheckedUncheckedDisabled(
                                  checkedColor: Colors.green,
                                  uncheckedColor: Colors.white,
                                ),
                                style: MSHCheckboxStyle.stroke,
                                onChanged: (selected) {
                                  _toggleCheckbox(task.id, isDone);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  task['task'],
                                  style: TextStyle(
                                    color: isDone ? Colors.green : Colors.white,
                                    fontSize: 20,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }
}
