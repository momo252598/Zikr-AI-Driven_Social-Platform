import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // import ScreenUtil
import 'package:software_graduation_project/screens/Signup/signup.dart';
import 'package:software_graduation_project/screens/prayers/prayers_test.dart';
import 'package:software_graduation_project/screens/signin/signin.dart';
import 'package:software_graduation_project/components/signup/sign_up_form.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'package:software_graduation_project/screens/prayers/prayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true, // this sets _minTextAdapt
      builder: (context, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Skeleton();
  }
}
