import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dart_random_choice/dart_random_choice.dart';
import 'package:slogovi_app/enums/levels.dart';

class GameScreen extends StatefulWidget {
  final Level level;
  const GameScreen({super.key, required this.level});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  int score = 0;
  bool isGameActive = false;
  DateTime? wordStartTime;
  final List<int> lastScores = [];

  String? username;
  String? groupName;
  int localHighScore = 0;

  // In-memory entries for current level
  List<MapEntry<String, double>> entries = [];
  late final Box<int> masteryBox;
  String? currentEntry;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // select box based on level
    masteryBox = Hive.box<int>('masteryBox${widget.level.name}');
    _loadLocalData().then((_) {
      _loadEntries().then((_) {
        _startGame();
        setState(() => isLoading = false);
      });
    });
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    groupName = prefs.getString('groupName');
    final key = 'highscore${widget.level.name}';
    localHighScore = prefs.getInt(key) ?? 0;
  }

  Future<void> _loadEntries() async {
    // Load the new TSV with words and syllables
    final raw = await rootBundle.loadString('assets/syllables.tsv');
    final lines = raw.trim().split('\n').skip(1);
    entries = [];
    for (var line in lines) {
      final parts = line.split(RegExp(r'\s+'));
      final word = parts[0];
      final freq = double.tryParse(parts[1]) ?? 0;
      final syllableList = parts.length > 3 && parts[3].isNotEmpty
          ? parts[3].split(',')
          : <String>[];

      switch (widget.level) {
        case Level.L1:
          // each individual syllable
          for (var syl in syllableList) {
            entries.add(MapEntry(syl, freq));
          }
          break;
        case Level.L2:
          if (syllableList.isNotEmpty) {
            entries.add(MapEntry(syllableList.join('-'), freq));
          }
          break;
        case Level.L3:
          // whole word
          entries.add(MapEntry(word, freq));
          break;
      }
    }
  }

  void _startGame() {
    score = 0;
    lastScores.clear();
    isGameActive = true;
    _nextEntry();
  }

  void _nextEntry() {
    // filter out mastered
    var available = entries.where((e) => masteryBox.get(e.key, defaultValue: 0)! < 3).toList();
    if (available.isEmpty) {
      // reset mastery for this level
      for (var e in entries) {
        masteryBox.put(e.key, 0);
      }
      available = List.from(entries);
    }
    // weighted pick
    final options = available.map((e) => e.key);
    final weights = available.map((e) => e.value);
    currentEntry = randomChoice<String>(options, weights);
    wordStartTime = DateTime.now();
    setState(() {});
  }

  Future<void> _updateHighScore(int newScore) async {
    if (username == null || groupName == null) return;
    if (newScore <= localHighScore) return;
    localHighScore = newScore;
    final prefs = await SharedPreferences.getInstance();
    final key = 'highscore${widget.level.name}';
    await prefs.setInt(key, newScore);
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .where('groupName', isEqualTo: groupName)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({key: newScore});
    }
  }

  void onCorrectPressed() {
    if (!isGameActive || currentEntry == null) return;
    final now = DateTime.now();
    final elapsed = wordStartTime == null
        ? double.infinity
        : now.difference(wordStartTime!).inMilliseconds / 1000.0;
    int points;
    if (elapsed <= 2) {
      // increment mastery count
      final cnt = masteryBox.get(currentEntry, defaultValue: 0)! + 1;
      masteryBox.put(currentEntry, cnt);
      points = 3;
    } else if (elapsed <= 4) {
      points = 2;
    } else {
      points = 1;
    }

    lastScores.add(points);
    if (lastScores.length > 100) lastScores.removeAt(0);
    score = lastScores.fold(0, (a, b) => a + b);

    _updateHighScore(score);

    _nextEntry();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final display = currentEntry?.toLowerCase() ?? '';
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: SafeArea(
        child: Stack(
          children: [
             // Score display (top left)
            Positioned(
              left: 20, top: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text('Поени: $score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            // Back button (top right)
            Positioned(
              right: 20, top: 20,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.7), foregroundColor: Colors.white),
                child: const Text('Назад', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            // Word display (center of screen)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  display,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            // Next button (bottom right)
            Positioned(
              right: 20, bottom: 20,
              child: ElevatedButton(
                onPressed: onCorrectPressed,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('ТОЧНО!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
