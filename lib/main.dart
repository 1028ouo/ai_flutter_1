import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int score = 0;
  Timer? gameTimer;
  Timer? dropTimer;
  Random random = Random();
  List<List<int>> grid = [
    [0, 1, 0],
    [1, 0, 0],
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1],
    [2, 2, 2]
  ]; // 初始方塊位置
  bool isGameOver = false;
  bool isGameStarted = false;
  final double blockHeight = 50.0; // 方塊高度
  int remainingTime = 60; // 剩餘時間

  @override
  void initState() {
    super.initState();
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      score = 0;
      isGameOver = false;
      remainingTime = 60;
      grid = [
        [0, 1, 0],
        [1, 0, 0],
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1],
        [2, 2, 2]
      ]; // 初始化方塊位置
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          isGameOver = true;
          timer.cancel();
          dropTimer?.cancel();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('遊戲結束'),
              content: Text('你在一分鐘內消除了 $score 個方塊'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    startGame();
                  },
                  child: Text('再來一次'),
                ),
              ],
            ),
          );
        }
      });
    });
  }

  void onButtonPressed(int column) {
    setState(() {
      if (grid[4][column] == 1) {
        grid[4][column] = 0;
        score++;
        // 隨機生成新的方塊位置，確保每一列只有一個方塊
        int newColumn = random.nextInt(3);
        while (grid[0][newColumn] == 1) {
          newColumn = random.nextInt(3);
        }
        grid.insert(0, [0, 0, 0]);
        grid[0][newColumn] = 1;
        grid.removeLast();
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    dropTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('打方塊遊戲'),
      ),
      body: Column(
        children: [
          if (isGameStarted)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text('剩餘時間: $remainingTime 秒'),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                if (isGameStarted)
                  for (int i = 0; i < 5; i++)
                    for (int j = 0; j < 3; j++)
                      if (grid[i][j] == 1)
                        Positioned(
                          top: MediaQuery.of(context).size.height / 6 * i,
                          left: MediaQuery.of(context).size.width / 3 * j,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            height: blockHeight,
                            color: Colors.red,
                          ),
                        ),
              ],
            ),
          ),
          if (!isGameStarted)
            ElevatedButton(
              onPressed: startGame,
              child: Text('開始遊戲'),
            ),
          if (isGameStarted)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onButtonPressed(0),
                    child: Text('按鈕 1'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onButtonPressed(1),
                    child: Text('按鈕 2'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onButtonPressed(2),
                    child: Text('按鈕 3'),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('得分: $score'),
          ),
        ],
      ),
    );
  }
}
