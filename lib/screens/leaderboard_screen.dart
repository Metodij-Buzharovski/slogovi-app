import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? groupName;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      groupName = prefs.getString('groupName');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (groupName == null || groupName!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leaderboard')),
        body: const Center(
          child: Text('Please join a group first to view the scores'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard: $groupName')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('groupName', isEqualTo: groupName)
            .orderBy('highscore', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users in this group yet.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data()! as Map<String, dynamic>;
              final username = data['username'] ?? 'unknown';
              final high = data['highscore'] ?? 0;
              return ListTile(
                leading: Text('#${index + 1}', style: const TextStyle(fontSize: 20)),
                title: Text(username, style: const TextStyle(fontSize: 18)),
                trailing: Text(high.toString(), style: const TextStyle(fontSize: 18)),
              );
            },
          );
        },
      ),
    );
  }
}
