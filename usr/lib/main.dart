import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SantaGameApp());
}

class SantaGameApp extends StatelessWidget {
  const SantaGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هدايا سانتا - الجزر الفضائية',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // إعدادات اللعبة
  static const double santaSize = 50.0;
  static const double giftSize = 40.0;
  static const double gameSpeed = 5.0;
  
  // حالة اللعبة
  bool isPlaying = false;
  int score = 0;
  double santaX = 0.0; // الموضع الأفقي لسانتا (-1.0 إلى 1.0)
  List<Gift> gifts = [];
  List<Star> stars = [];
  Timer? gameLoopTimer;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    // إنشاء نجوم للخلفية
    for (int i = 0; i < 50; i++) {
      stars.add(Star(
        x: random.nextDouble() * 2 - 1,
        y: random.nextDouble() * 2 - 1,
        size: random.nextDouble() * 3 + 1,
      ));
    }
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      gifts.clear();
      santaX = 0.0;
    });

    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      updateGame();
    });
  }

  void stopGame() {
    gameLoopTimer?.cancel();
    setState(() {
      isPlaying = false;
    });
    showGameOverDialog();
  }

  void updateGame() {
    setState(() {
      // تحريك الهدايا
      for (var gift in gifts) {
        gift.y += 0.01 * gameSpeed;
      }

      // إزالة الهدايا التي خرجت من الشاشة
      gifts.removeWhere((gift) => gift.y > 1.2);

      // إضافة هدايا جديدة
      if (random.nextInt(100) < 3) { // احتمالية ظهور هدية
        gifts.add(Gift(
          x: random.nextDouble() * 2 - 1,
          y: -1.2,
          type: random.nextInt(3), // 0: أحمر، 1: أخضر، 2: ذهبي
        ));
      }

      // التحقق من التصادم
      checkCollisions();
    });
  }

  void checkCollisions() {
    // تحويل إحداثيات سانتا للتحقق
    // سانتا في الأسفل، y حوالي 0.8
    double santaY = 0.8;
    double collisionThreshold = 0.15; // مسافة التصادم

    List<Gift> collectedGifts = [];

    for (var gift in gifts) {
      double dx = (gift.x - santaX).abs();
      double dy = (gift.y - santaY).abs();

      if (dx < collisionThreshold && dy < collisionThreshold) {
        collectedGifts.add(gift);
        score += 10 * (gift.type + 1); // نقاط مختلفة حسب نوع الهدية
      }
    }

    // إزالة الهدايا المجمعة
    for (var gift in collectedGifts) {
      gifts.remove(gift);
    }
    
    // شرط الخسارة (اختياري: إذا لمس "قنبلة" أو شيء آخر، هنا بسيط فقط تجميع)
  }

  void moveSanta(double delta) {
    if (!isPlaying) return;
    setState(() {
      santaX += delta;
      if (santaX < -1.0) santaX = -1.0;
      if (santaX > 1.0) santaX = 1.0;
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('انتهت اللعبة!'),
        content: Text('لقد جمعت $score نقطة!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startGame();
            },
            child: const Text('لعب مرة أخرى'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0033), // لون فضاء داكن
      body: Stack(
        children: [
          // الخلفية والنجوم
          ...stars.map((star) => Positioned(
            left: (star.x + 1) / 2 * MediaQuery.of(context).size.width,
            top: (star.y + 1) / 2 * MediaQuery.of(context).size.height,
            child: Container(
              width: star.size,
              height: star.size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          )),

          // جزيرة فضائية (الأرضية)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blueGrey.withOpacity(0.5), Colors.transparent],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(1000)), // شكل مقوس
              ),
            ),
          ),

          // الهدايا المتساقطة
          ...gifts.map((gift) => Positioned(
            left: (gift.x + 1) / 2 * MediaQuery.of(context).size.width - giftSize / 2,
            top: (gift.y + 1) / 2 * MediaQuery.of(context).size.height - giftSize / 2,
            child: Icon(
              Icons.card_giftcard,
              color: gift.getColor(),
              size: giftSize,
            ),
          )),

          // سانتا
          Positioned(
            left: (santaX + 1) / 2 * MediaQuery.of(context).size.width - santaSize / 2,
            bottom: MediaQuery.of(context).size.height * 0.1, // موضع ثابت رأسياً
            child: Column(
              children: [
                const Icon(
                  Icons.person, // يمكن استبداله بصورة سانتا
                  color: Colors.red,
                  size: santaSize,
                ),
                Container(
                  width: santaSize,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              ],
            ),
          ),

          // واجهة المستخدم (النقاط وزر البدء)
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              'النقاط: $score',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          if (!isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'هدايا سانتا\nالجزر الفضائية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: const Text('ابدأ اللعب', style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // أزرار التحكم (للهواتف)
          if (isPlaying)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTapDown: (_) => moveSanta(-0.2),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 40),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => moveSanta(0.2),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 40),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// كلاسات مساعدة
class Gift {
  double x;
  double y;
  int type;

  Gift({required this.x, required this.y, required this.type});

  Color getColor() {
    switch (type) {
      case 0: return Colors.redAccent;
      case 1: return Colors.greenAccent;
      case 2: return Colors.amber;
      default: return Colors.white;
    }
  }
}

class Star {
  double x;
  double y;
  double size;

  Star({required this.x, required this.y, required this.size});
}
