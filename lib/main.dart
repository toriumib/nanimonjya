import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled/views/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '＋で即決、時には自分で決断'),
      debugShowCheckedModeBanner: false,
    );
  }
}







// void main() {
//   runApp(RandomShapesApp());
// }
//
// class RandomShapesApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: RandomShapesScreen(),
//     );
//   }
// }
//
// class RandomShapesScreen extends StatefulWidget {
//   @override
//   _RandomShapesScreenState createState() => _RandomShapesScreenState();
// }
//
// class _RandomShapesScreenState extends State<RandomShapesScreen> {
//   List<Widget> shapes = [];
//
//   void _addRandomShape() {
//     setState(() {
//       final rng = Random();
//       if (rng.nextBool()) {
//         shapes.add(
//           Positioned(
//             left: rng.nextDouble() * 300,
//             top: rng.nextDouble() * 300,
//             child: CircleAvatar(
//               backgroundColor: Colors.blue,
//               radius: 30,
//             ),
//           ),
//         );
//       } else {
//         shapes.add(
//           Positioned(
//             left: rng.nextDouble() * 300,
//             top: rng.nextDouble() * 300,
//             child: Icon(
//               Icons.clear,
//               color: Colors.red,
//               size: 60,
//             ),
//           ),
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('＋で即決、時には自分で決断'),
//       ),
//       body: Stack(
//         children: shapes,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addRandomShape,
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }
