import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DataProvider extends ChangeNotifier {
  List<dynamic> pensionPots = [];
  List<dynamic> drawdowns = [];
  Map<String, dynamic> statePension = {};
  List<double> simulationResults = [];
  List<dynamic> users = [];

  // ───────────────────────── Pension Pots ─────────────────────────

  Future<void> fetchPensionPots() async {
    pensionPots = await ApiService.getList('pension_pots');
    notifyListeners();
  }

  Future<void> addPensionPot(Map<String, dynamic> pot) async {
    await ApiService.post('pension_pots', pot);
    await fetchPensionPots();
  }

  Future<void> deletePensionPot(int id) async {
    await ApiService.delete('pension_pots/$id');
    await fetchPensionPots();
  }

  // ───────────────────────── Drawdowns ─────────────────────────

  Future<void> fetchDrawdowns() async {
    drawdowns = await ApiService.getList('drawdowns');
    notifyListeners();
  }

  Future<void> addDrawdown(Map<String, dynamic> drawdown) async {
    await ApiService.post('drawdowns', drawdown);
    await fetchDrawdowns();
  }

  Future<void> deleteDrawdown(int id) async {
    await ApiService.delete('drawdowns/$id');
    await fetchDrawdowns();
  }

  // ───────────────────────── State Pension ─────────────────────────

  Future<void> fetchStatePension() async {
    try {
      final obj = await ApiService.getOne('state_pension');
      statePension = obj;
    } catch (_) {
      statePension = {};
    }
    notifyListeners();
  }

  Future<void> setStatePension(Map<String, dynamic> sp) async {
    await ApiService.post('state_pension', sp);
    await fetchStatePension();
  }

  // ───────────────────────── Simulation ─────────────────────────

  Future<void> simulate() async {
    final res = await ApiService.post('simulate', {});
    simulationResults = List<double>.from(res);
    notifyListeners();
  }

  // ───────────────────────── Admin Users ─────────────────────────

  Future<void> fetchUsers() async {
    users = await ApiService.getList('admin/users');
    notifyListeners();
  }

  Future<void> lockUser(int userId) async {
    await ApiService.post('admin/lock_user', {'user_id': userId});
    await fetchUsers();
  }

  Future<void> resetUserPassword(int userId, String newPassword) async {
    await ApiService.post('admin/reset_password', {
      'user_id': userId,
      'new_password': newPassword,
    });
    await fetchUsers();
  }
}
