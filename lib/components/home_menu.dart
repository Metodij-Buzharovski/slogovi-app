import 'package:flutter/material.dart';
import 'package:slogovi_app/components/create_group_button.dart';
import 'package:slogovi_app/components/join_group_button.dart';
import 'package:slogovi_app/components/play_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slogovi_app/screens/leaderboard_screen.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  Future<void> _saveLocal(String username, String groupName, int highscore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('groupName', groupName);
    await prefs.setInt('highscore', highscore);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          PlayButton(),

          // Leaderboard button (purple)
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                );
              },
              child: Container(
                color: const Color(0xFF9b59b6),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right side buttons stack
          Expanded(
            child: Column(
              children: [
                // Create group button
                CreateGroupButton(saveLocal: _saveLocal),

                // Join group button
                JoinGroupButton(saveLocal: _saveLocal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
