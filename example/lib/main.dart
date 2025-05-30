import 'package:flutter/material.dart';
import 'package:random_image_viewer/random_image_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

double _currentRotationAngle = 0.0;

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Random Image Viewer"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: <Widget>[
              // Here I am just using few properties/parameters, you can try all
              RandomImageViewer(
                height: 200,
                enableRotation: true,
                progressIndicatorColor: Colors.red,
                onTap: () {
                  debugPrint("This is working onTap");
                },
                initialRotation: -45,
                imagePath:
                    "https://plus.unsplash.com/premium_photo-1734354794200-49aec81e395d?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
                // errorImagePath: "assets/images/mental.jpg",
              ),
              RandomImageViewer(
                enableZoom: true,
                doubleTapZoom: true,
                maxScale: 50,
                onTap: () {
                  print("assets/images/livinh.svg");
                },
                height: 200,
                imagePath: "assets/images/livinh.svg",
              ),
              RandomImageViewer(
                enableZoom: true,
                maxScale: 50,
                onTap: () {
                  print("assets/images/gif.gif");
                },
                height: 200,
                imagePath: "assets/images/gif.gif",
              ),
              RandomImageViewer(
                enableZoom: true,
                maxScale: 50,
                onTap: () {
                  print("assets/images/bmp.bmp");
                },
                height: 200,
                imagePath: "assets/images/bmp.bmp",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
