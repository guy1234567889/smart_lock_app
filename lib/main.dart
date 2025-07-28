import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(SmartLockApp());
}

class SmartLockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'השכרת מנעול',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: QRScreen(),
    );
  }
}

class QRScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('השכרה זמנית')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('סרוק את הברקוד להתקנת האפליקציה'),
            SizedBox(height: 20),
            SizedBox(width: 250, height: 250, child: QRViewExample()),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentScreen()),
              ),
              child: Text('המשך לתשלום'),
            ),
          ],
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: (ctrl) {
        controller = ctrl;
        ctrl.scannedDataStream.listen((scanData) {
          setState(() {
            result = scanData;
          });
        });
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('תשלום')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('תשלום חד-פעמי עבור 30 דקות שימוש', style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LockScreen()),
              ),
              child: Text('שלם והפעל'),
            ),
          ],
        ),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  int remainingSeconds = 1800;
  Timer? timer;
  int usageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
        if (remainingSeconds == 600 || remainingSeconds == 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('תזכורת: נותרו ${remainingSeconds ~/ 60} דקות')),
          );
        }
      }
    });
  }

  Future<void> _loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    usageCount = prefs.getInt('usage') ?? 0;
    usageCount++;
    await prefs.setInt('usage', usageCount);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String time =
        "${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: Text('ניהול השכרה')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('זמן שנותר', style: TextStyle(fontSize: 22)),
            SizedBox(height: 10),
            Text(time, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            ElevatedButton(onPressed: () {}, child: Text('נעל / פתח')),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (usageCount >= 5) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RewardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('עליך להשתמש עוד ${5 - usageCount} פעמים לקבלת הטבה')),
                  );
                }
              },
              child: Text('בדוק הטבה'),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('הטבה')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('לאחר 5 שימושים – השכרה חינם!', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Icon(Icons.card_giftcard, size: 80, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
