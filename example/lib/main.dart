import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gesture_grid_view/gesture_grid_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gesture Grid View Demo')),
      body: GestureGridView(
        padding: EdgeInsets.all(16),
        minAxisCount: 1,
        maxAxisCount: 6,
        initialAxisCount: 6,
        childAspectRatio: 1.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: 50,
        onAxisChanged: (newAxisCount) {
          HapticFeedback.mediumImpact();
        },
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue[100 * ((index % 9) + 1)],
            ),
            child: GestureDetector(
              child: Center(
                child: Text('$index'),
              ),
            ),
          );
        },
      ),
    );
  }
}
