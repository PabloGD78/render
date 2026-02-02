import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';

final AuthService _authService = AuthService();

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
                      Navigator.pushNamed(context, '/');
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
          child: const _RegisterForm(),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// --- FORMULARIO DE REGISTRO ---
// ------------------------------------------------------------------

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _tlfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Guardamos el valor seleccionado (puede estar en mayúsculas para la vista)
  String _tipoSeleccionado = '';
  bool _tipoError = false;

  void _showMessageDialog(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // 1. Validar que se haya seleccionado un tipo
    if (_tipoSeleccionado.isEmpty) {
      setState(() => _tipoError = true);
      _showMessageDialog(
        'Error',
        'Por favor selecciona un tipo de cuenta.',
        false,
      );
      return;
    } else {
      setState(() => _tipoError = false);
    }

    // 2. Validar contraseñas
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessageDialog('Error', 'Las contraseñas no coinciden.', false);
      return;
    }

    // 3. Enviar al backend (convertimos el tipo a minúsculas para la BD)
    final result = await _authService.register(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      tlf: _tlfController.text.trim(),
      correo: _emailController.text.trim(),
      contrasenia: _passwordController.text,
      tipo: _tipoSeleccionado
          .toLowerCase(), // ¡IMPORTANTE! Convierte 'Comprador' a 'comprador'
    );

    if (result['success'] == true) {
      _showMessageDialog('Éxito', result['message'], true);
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _showMessageDialog('Error', result['message'], false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _tlfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Widget auxiliar para crear los Chips y ahorrar código
  Widget _buildChoiceChip(String label) {
    final bool isSelected = _tipoSeleccionado == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.textFieldBackground,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.iconColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _tipoSeleccionado = label),
    );
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

            _RegisterTextField(
              controller: _nombreController,
              hintText: 'Nombre',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            _RegisterTextField(
              controller: _apellidosController,
              hintText: 'Apellidos',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            _RegisterTextField(
              controller: _tlfController,
              hintText: 'Teléfono',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            _RegisterTextField(
              controller: _emailController,
              hintText: 'Usuario@gmail.com',
              icon: Icons.mail_outline,
            ),
            const SizedBox(height: 20),

            _RegisterTextField(
              controller: _passwordController,
              hintText: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 20),

            _RegisterTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirmar contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 20),

            // SECCIÓN TIPO DE USUARIO (Actualizada)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrarse como:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // Usamos Wrap para que los botones bajen de línea si no caben
                Wrap(
                  spacing: 10.0, // Espacio horizontal entre botones
                  runSpacing: 5.0, // Espacio vertical si bajan de línea
                  children: [
                    _buildChoiceChip('Particular'),
                    _buildChoiceChip('Profesional'),
                    _buildChoiceChip('Comprador'), // ¡Aquí está el nuevo!
                  ],
                ),
                if (_tipoError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Por favor selecciona un tipo de cuenta',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Crear cuenta',
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
                Navigator.pushNamed(context, '/login');
              },
              child: const Text(
                'Iniciar sesión ↗',
                style: TextStyle(color: AppColors.iconColor, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// --- WIDGETS AUXILIARES ---
// ------------------------------------------------------------------

class _RegisterTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _RegisterTextField({
    required this.hintText,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_RegisterTextField> createState() => _RegisterTextFieldState();
}

class _RegisterTextFieldState extends State<_RegisterTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AppColors.hintTextColor),
        prefixIcon: Icon(widget.icon, color: AppColors.iconColor),
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
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.iconColor,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
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
