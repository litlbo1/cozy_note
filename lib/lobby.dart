import 'package:cozy_note/todo_list_sreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final CollectionReference _todos = FirebaseFirestore.instance.collection('groups');

  void _addGroup() async {
    if (_controller.text.isNotEmpty) {
      await _todos.add({'group': _controller.text, 'created_at': Timestamp.now()});
      _controller.clear();
    }
  }

  Future<void> _deleteGroupWithTodos(String groupId) async {
    // Получаем ссылку на подколлекцию todos внутри группы
    final CollectionReference todosRef = _todos.doc(groupId).collection('todos');

    // Получаем все документы в подколлекции todos
    final QuerySnapshot todosSnapshot = await todosRef.get();

    // Удаляем каждый документ в подколлекции todos
    for (var doc in todosSnapshot.docs) {
      await doc.reference.delete();
    }

    // После удаления всех todo удаляем саму группу
    await _todos.doc(groupId).delete();
  }

  void _showDeleteConfirmation(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Удалить группу?"),
          content: const Text("Вы уверены, что хотите удалить эту группу и все связанные todo?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGroupWithTodos(groupId);
              },
              child: const Text("Удалить"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        tooltip: 'Добавить группу',
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Добавить группу"),
                content: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      hintText: "Введите до 8 символов",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Введите текст";
                      } else if (value.length > 8) {
                        return "Максимум 8 символов";
                      }
                      return null;
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Отмена"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _addGroup();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("Сохранить"),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      backgroundColor: const Color(0xff121212),
      body: StreamBuilder(
        stream: _todos.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final userSnapshot = snapshot.data?.docs;
          if (userSnapshot == null || userSnapshot.isEmpty) {
            return const Center(child: Text("Нет данных", style: TextStyle(color: Colors.white)));
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 120,
            ),
            itemCount: userSnapshot.length,
            itemBuilder: (context, index) {
              final groupData = userSnapshot[index];
              return GestureDetector(
                onLongPress: () => _showDeleteConfirmation(context, groupData.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: OpenContainer(
                    closedColor: Colors.yellow,
                    openColor: const Color(0xff121212),
                    closedElevation: 5.0,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    transitionDuration: const Duration(milliseconds: 600),
                    closedBuilder: (context, openContainer) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.yellow,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 232, 232, 232).withOpacity(0.2),
                            spreadRadius: 8,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 30, left: 30, right: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 8,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              groupData["group"],
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                    openBuilder: (context, _) => TodoListScreen(groupId: groupData.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
