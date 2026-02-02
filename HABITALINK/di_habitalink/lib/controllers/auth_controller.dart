import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart'; // Asegúrate de que esta ruta sea correcta

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthController() {
    // Cargar la sesión guardada al iniciar el controlador
    _loadCurrentUser();
  }

  // --- LÓGICA DE CARGA DE SESIÓN ---

  Future<void> _loadCurrentUser() async {
    final userData = await _authService.getLoggedInUser();

    // Verifica si hay datos válidos (nombre y token)
    if (userData['nombre']?.isNotEmpty == true &&
        userData['token']?.isNotEmpty == true) {
      _currentUser = UserModel.fromMap(userData);
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  // --- LÓGICA DE LOGIN ---

  Future<bool> login({
    required String correo,
    required String contrasenia,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      correo: correo,
      contrasenia: contrasenia,
    );

    if (result['success'] == true) {
      // Login exitoso: Re-cargar el usuario desde SharedPreferences
      await _loadCurrentUser();
      return true;
    } else {
      // Login fallido
      _errorMessage =
          result['message'] ?? 'Error de inicio de sesión desconocido.';
      notifyListeners();
      return false;
    }
  }

  // --- LÓGICA DE REGISTRO ---

  Future<bool> register({
    required String nombre,
    required String apellidos,
    required String tlf,
    required String correo,
    required String contrasenia,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      nombre: nombre,
      apellidos: apellidos,
      tlf: tlf,
      correo: correo,
      contrasenia: contrasenia,
    );

    if (result['success'] == true) {
      return true; // Éxito
    } else {
      _errorMessage = result['message'] ?? 'Error de registro desconocido.';
      notifyListeners();
      return false; // Fallo
    }
  }

  // --- LÓGICA DE LOGOUT ---

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
