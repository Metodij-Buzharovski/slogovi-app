import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slogovi_app/enums/levels.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? groupName;
  String? currentUsername;
  Level _filterLevel = Level.L1;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      groupName = prefs.getString('groupName');
      currentUsername = prefs.getString('username');
    });
  }

  Widget _buildRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icon(Icons.emoji_events, color: Colors.amber, size: 30);
      case 2:
        return Icon(Icons.emoji_events, color: Colors.grey[400]!, size: 30);
      case 3:
        return Icon(Icons.emoji_events, color: Colors.brown[400]!, size: 30);
      default:
        return Text('#$rank', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3498db);
    const accentColor = Color(0xFF2980b9);

    // If not in a group, prompt to join/create
    if (groupName == null || groupName!.isEmpty) {
      return Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: const Text('Табела', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: accentColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 80, color: Colors.white70),
                const SizedBox(height: 20),
                const Text(
                  'Приклучи се или креирај група за да ги видиш резултатите',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final scoreField = 'highscore${_filterLevel.name}';

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('Табела: $groupName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: accentColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Level filter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: Level.values.map((lvl) {
                final isSelected = lvl == _filterLevel;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.white : Colors.grey[600],
                      foregroundColor: isSelected ? accentColor : Colors.white,
                    ),
                    onPressed: () => setState(() => _filterLevel = lvl),
                    child: Text(lvl.name),
                  ),
                );
              }).toList(),
            ),
          ),
          // Leaderboard list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('groupName', isEqualTo: groupName)
                  .orderBy(scoreField, descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data()! as Map<String, dynamic>;
                    final usr = data['username'] ?? '';
                    final sc  = data[scoreField] ?? 0;
                    final isCurrent = currentUsername == usr;
                    return Card(
                      elevation: isCurrent ? 6 : 3,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: isCurrent ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                      ),
                      color: isCurrent ? accentColor.withOpacity(0.8) : accentColor.withOpacity(0.5),
                      child: ListTile(
                        leading: _buildRankIcon(index + 1),
                        title: Text(usr, style: TextStyle(color: Colors.white, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600)),
                        trailing: Text(sc.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
