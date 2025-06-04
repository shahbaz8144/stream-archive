import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_archive/screens/all_doc_list.dart';
import 'package:stream_archive/screens/user_login.dart';

import 'data/user_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // runApp(const MyApp());
  runApp(
    // ChangeNotifierProvider(
    //   create: (context) => UserDataProvider(),
    //   child:
      MyApp(),
    // ),

  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // Check if user is logged in
    if (isLoggedIn) {
      return const AllDocList(); // Show dashboard if logged in
    } else {
      return const UserLogIn(); // Show login screen if not logged in
    }
  }

  // This widget is the root of your application ok.
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   title: 'Flutter Demo',
    //   theme: ThemeData(
    //
    //     colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    //     useMaterial3: true,
    //   ),
    //   debugShowCheckedModeBanner: false,
    //
    //   home: const UserLogIn(),
    // );
    return FutureBuilder<Widget>(
        future: _getInitialScreen(), // Determine the screen to show
        builder: (context, snapshot) {

          return GetMaterialApp(
            title: 'Stream Archive',
            theme: ThemeData(
              unselectedWidgetColor: Colors.grey,
            ),
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            home: snapshot.data ?? const UserLogIn(), // Show the screen returned from _getInitialScreen
          );
        }

    );
  }
}


