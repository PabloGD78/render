import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart'; // 🚀 Importado para el botón de crear cuenta
import 'admin/admin_dashboard_screen.dart'; // 🚀 Importado para el flujo de Admin

final AuthService _authService = AuthService();

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.kPadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.home,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                        (route) => false,
                      );
                    },
                    tooltip: 'Volver a la página principal',
                  ),
                  Image.asset(
                    'assets/logo/LogoSinFondo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(
              color: AppColors.primary,
              height: 40,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavMenuItem(title: 'Comprar'),
                  NavMenuItem(title: 'Alquilar'),
                  NavMenuItem(title: 'Valoración'),
                  NavMenuItem(title: 'Favoritos'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.kPadding),
          child: const _LoginForm(),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _showMessageDialog(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessageDialog("Por favor, rellena todos los campos", false);
      return;
    }

    try {
      final result = await _authService.login(
        correo: _emailController.text.trim(),
        contrasenia: _passwordController.text,
      );

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final userData = result['user'];

        // Guardar datos y obtener el ROL
        final String userRole =
            userData['rol']?.toString().toLowerCase() ?? 'usuario';

        await prefs.setString('userEmail', _emailController.text.trim());
        await prefs.setString('userPassword', _passwordController.text);
        await prefs.setString('userName', userData['nombre'] ?? 'Usuario');
        await prefs.setString('rol', userRole);
        await prefs.setString(
          'tipo',
          userData['tipo']?.toLowerCase() ?? 'particular',
        );

        final String userId = userData['id']?.toString() ?? '';
        await prefs.setString('idUsuario', userId);

        if (!mounted) return;
        _showMessageDialog("Bienvenido, ${userData['nombre']}", true);

        // 🚀 Lógica de Navegación por Rol
        if (userRole == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        _showMessageDialog(result['message'] ?? 'Error de credenciales', false);
      }
    } catch (e) {
      debugPrint("Error en login: $e");
      _showMessageDialog("Error de conexión con el servidor", false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.iconColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 30),
            _LoginTextField(
              controller: _emailController,
              hintText: 'Usuario@gmail.com',
              icon: Icons.mail_outline,
            ),
            const SizedBox(height: 20),
            _LoginTextField(
              controller: _passwordController,
              hintText: '.........',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // 🚀 Navegar a la página de Registro
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text(
                'Crear cuenta ↗',
                style: TextStyle(color: AppColors.iconColor, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;

  const _LoginTextField({
    required this.hintText,
    required this.icon,
    required this.controller,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.hintTextColor),
        prefixIcon: Icon(icon, color: AppColors.iconColor),
        filled: true,
        fillColor: AppColors.textFieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 25,
        ),
      ),
    );
  }
}

class NavMenuItem extends StatelessWidget {
  final String title;
  const NavMenuItem({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }
}
