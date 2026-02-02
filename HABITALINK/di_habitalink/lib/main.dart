import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/home_page.dart';
import 'view/login_page.dart';
import 'view/register_page.dart';
import 'view/search_results_page.dart';
import 'theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verificar si el usuario ya está logueado
  final prefs = await SharedPreferences.getInstance();
  final bool userLoggedIn = prefs.getBool('userLoggedIn') ?? false;

  runApp(MyApp(userLoggedIn: userLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool userLoggedIn; // parámetro obligatorio

  const MyApp({super.key, required this.userLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitalink Inmobiliaria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary),
        fontFamily: 'Roboto',
      ),
      // Ruta inicial según si el usuario está logueado
      initialRoute: userLoggedIn ? '/' : '/login',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/registro': (context) => const RegisterPage(),
        '/search_results': (context) => const SearchResultsPage(),
      },
    );
  }
}
