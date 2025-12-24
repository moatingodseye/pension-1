import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool loggedIn = false;

  Future<void> login(String username, String password) async {
    final res = await ApiService.post('login', {
      'username': username,
      'password': password,
    });
    if (res['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', res['token']);
      await ApiService.initToken();
      loggedIn = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    loggedIn = false;
    notifyListeners();
  }
}

