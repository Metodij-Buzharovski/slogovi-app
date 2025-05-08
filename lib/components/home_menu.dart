import 'package:flutter/material.dart';
import 'package:slogovi_app/components/create_group_button.dart';
import 'package:slogovi_app/components/join_group_button.dart';
import 'package:slogovi_app/components/play_button.dart';
import 'package:slogovi_app/screens/leaderboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  String? _username;
  String? _groupName;
  int _highscoreL1 = 0;
  int _highscoreL2 = 0;
  int _highscoreL3 = 0;

  bool get inGroup => _groupName != null && _groupName!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username    = prefs.getString('username');
      _groupName   = prefs.getString('groupName');
      _highscoreL1 = prefs.getInt('highscoreL1') ?? 0;
      _highscoreL2 = prefs.getInt('highscoreL2') ?? 0;
      _highscoreL3 = prefs.getInt('highscoreL3') ?? 0;
    });
  }

  Future<void> _saveLocal(String username, String groupName, int initialScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('groupName', groupName);
    // Initialize all level highscores
    await prefs.setInt('highscoreL1', initialScore);
    await prefs.setInt('highscoreL2', initialScore);
    await prefs.setInt('highscoreL3', initialScore);

    setState(() {
      _username    = username;
      _groupName   = groupName;
      _highscoreL1 = initialScore;
      _highscoreL2 = initialScore;
      _highscoreL3 = initialScore;
    });
  }

  Future<void> _leaveGroup() async {
    if (_username != null && _groupName != null) {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('users')
          .where('username', isEqualTo: _username)
          .where('groupName', isEqualTo: _groupName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('groupName');
    await prefs.remove('highscoreL1');
    await prefs.remove('highscoreL2');
    await prefs.remove('highscoreL3');

    setState(() {
      _username    = null;
      _groupName   = null;
      _highscoreL1 = 0;
      _highscoreL2 = 0;
      _highscoreL3 = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          PlayButton(),

          // Leaderboard
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
              child: Container(
                color: const Color(0xFF9b59b6),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text('Leaderboard', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Create & Join
          Expanded(
            child: Column(
              children: [
                CreateGroupButton(inGroup: inGroup, saveLocal: (u, g, h) => _saveLocal(u, g, h)),
                JoinGroupButton(inGroup: inGroup, saveLocal: (u, g, h) => _saveLocal(u, g, h), leaveGroup: _leaveGroup),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
