// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'dart:math';
// import '../components/ad_mob.dart';

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key, required this.title}) : super(key: key);

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final AdMob _adMob = AdMob();
//   int _counter = 0;
//   bool?
//       _isCircle; // Variable to hold the current random choice (circle or cross)

//   @override
//   void initState() {
//     super.initState();
//     _adMob.load();
//     _generateRandomChoice(); // Generate a random choice when the app starts
//   }

//   void _generateRandomChoice() {
//     final random = Random();
//     _isCircle =
//         random.nextBool(); // Randomly assign true (circle) or false (cross)
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _adMob.dispose();
//   }

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//       _generateRandomChoice(); // Generate a new random choice when the button is pressed
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 20), // Add some spacing
//             _isCircle != null
//                 ? _isCircle!
//                     ? const Icon(
//                         Icons.circle,
//                         size: 100,
//                         color: Colors.green,
//                       )
//                     : const Icon(
//                         Icons.close,
//                         size: 100,
//                         color: Colors.red,
//                       )
//                 : Container(), // Display circle or cross based on random choice
//             FutureBuilder(
//               future: AdSize.getAnchoredAdaptiveBannerAdSize(
//                   Orientation.portrait,
//                   MediaQuery.of(context).size.width.truncate()),
//               builder: (BuildContext context,
//                   AsyncSnapshot<AnchoredAdaptiveBannerAdSize?> snapshot) {
//                 if (snapshot.hasData) {
//                   return SizedBox(
//                     width: double.infinity,
//                     child: _adMob.getAdBanner(),
//                   );
//                 } else {
//                   return Container(
//                     height: _adMob.getAdBannerHeight(),
//                     color: Colors.white,
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

// void main() {
//   runApp(const MaterialApp(
//     title: 'Random Circle or Cross App',
//     home: MyHomePage(title: 'Random Circle or Cross'),
//   ));
// }
