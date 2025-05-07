import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroupButton extends StatelessWidget {
  final Future<void> Function(String username, String groupName, int highscore) saveLocal;

  const CreateGroupButton({super.key, required this.saveLocal});

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final TextEditingController _groupController = TextEditingController();
    final TextEditingController _userController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Направи група'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groupController,
                decoration: const InputDecoration(labelText: 'Име на група'),
              ),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'Корисничко име'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Откажи'),
            ),
            TextButton(
              onPressed: () async {
                final groupName = _groupController.text.trim().toLowerCase();
                final username = _userController.text.trim();
                if (groupName.isEmpty || username.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пополнете ги сите полиња.')),
                  );
                  return;
                }
                final firestore = FirebaseFirestore.instance;
                final groupRef = firestore.collection('groups').doc(groupName);
                final groupDoc = await groupRef.get();
                if (groupDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Групата "$groupName" веќе постои.')),
                  );
                  return;
                }
                // create group
                await groupRef.set({'name': groupName});
                // create user
                await firestore.collection('users').add({
                  'username': username,
                  'groupName': groupName,
                  'highscore': 0,
                });
                // save locally
                await saveLocal(username, groupName, 0);
                //TODO
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _showCreateGroupDialog(context),
        child: Container(
          color: const Color(0xFF2c3e50),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_add, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'Направи нова група',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
