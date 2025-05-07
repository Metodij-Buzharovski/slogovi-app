import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinGroupButton extends StatefulWidget {
  final Future<void> Function(String username, String groupName, int highscore) saveLocal;

  const JoinGroupButton({super.key, required this.saveLocal});

  @override
  _JoinGroupButtonState createState() => _JoinGroupButtonState();
}

class _JoinGroupButtonState extends State<JoinGroupButton> {
  String? username;
  String? groupName;

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      groupName = prefs.getString('groupName');
    });
  }

  Future<void> _leaveGroup() async {
    if (username == null || groupName == null) return;
    final firestore = FirebaseFirestore.instance;
    // find and delete user record
    final query = await firestore.collection('users')
      .where('username', isEqualTo: username)
      .where('groupName', isEqualTo: groupName)
      .limit(1)
      .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
    // clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('groupName');
    await prefs.remove('highscore');
    setState(() {
      username = null;
      groupName = null;
    });
  }

  Future<void> _showJoinGroupDialog() async {
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
                  'highscore': 0,
                });
                await widget.saveLocal(usr, grp, 0);
                //TODO
                if (!mounted) return;
                Navigator.of(context).pop();
                await _loadLocal();
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
    final inGroup = username != null && groupName != null;
    return Expanded(
      child: InkWell(
        onTap: inGroup ? _leaveGroup : _showJoinGroupDialog,
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
