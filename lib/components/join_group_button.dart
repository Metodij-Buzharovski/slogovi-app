import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinGroupButton extends StatelessWidget {
  final bool inGroup;
  final Future<void> Function(String username, String groupName, int highscore) saveLocal;
  final Future<void> Function() leaveGroup;

  const JoinGroupButton({super.key, required this.inGroup, required this.saveLocal, required this.leaveGroup});

  Future<void> _showJoinGroupDialog(BuildContext context) async {
    final TextEditingController _groupController = TextEditingController();
    final TextEditingController _userController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Влези во група'),
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
                final grp = _groupController.text.trim().toLowerCase();
                final usr = _userController.text.trim();
                if (grp.isEmpty || usr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пополнете ги сите полиња.')),
                  );
                  return;
                }
                final firestore = FirebaseFirestore.instance;
                final groupDoc = await firestore.collection('groups').doc(grp).get();
                if (!groupDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Групата "$grp" не постои.')),
                  );
                  return;
                }
                final existing = await firestore
                    .collection('users')
                    .where('groupName', isEqualTo: grp)
                    .where('username', isEqualTo: usr)
                    .limit(1)
                    .get();
                if (existing.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Корисничкото име "$usr" веќе постои во групата.')),
                  );
                  return;
                }
                await firestore.collection('users').add({
                  'username': usr,
                  'groupName': grp,
                  'highscoreL1': 0,
                  'highscoreL2': 0,
                  'highscoreL3': 0,
                });
                await saveLocal(usr, grp, 0);
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
        onTap: inGroup ? leaveGroup : () => _showJoinGroupDialog(context),
        child: Container(
          color: inGroup ? Colors.red.withOpacity(0.7) : const Color(0xFF2ecc71),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  inGroup ? Icons.logout : Icons.login,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  inGroup ? 'Излези од групата' : 'Влези во група',
                  style: const TextStyle(
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
