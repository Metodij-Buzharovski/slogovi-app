import 'package:flutter/material.dart';
import 'package:slogovi_app/enums/levels.dart';
import 'package:slogovi_app/screens/game_screen.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _showLevelDialog(context),
        child: Container(
          color: const Color(0xFF2ecc71),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 32),
                SizedBox(width: 8),
                Text(
                  'Играј',
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
    );
  }

  void _showLevelDialog(BuildContext context) async {
    final selected = await showDialog<Level>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Избери ниво'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Level.values.map((level) {
              final label = level.toString().split('.').last;
              return ListTile(
                title: Text(label),
                onTap: () => Navigator.of(context).pop(level),
              );
            }).toList(),
          ),
        );
      },
    );
    if (selected != null) {
      // Navigate to GameScreen with chosen level
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(level: selected),
        ),
      );
    }
  }
}