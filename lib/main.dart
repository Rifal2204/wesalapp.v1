import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wesalapp/screens/Rifalscreens/activity_details_screen.dart';
import 'firebase_options.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/discover_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وصال',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/discover': (context) => const DiscoverScreen(), 
      '/activity-details': (context) {
    final activityId = ModalRoute.of(context)!.settings.arguments as String;
    return ActivityDetailsScreen(activityId: activityId);
      },
      }
    );
  }
}
