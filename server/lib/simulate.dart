import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';


Future<Response> simulate(Request req) async {
  final uid = req.context['uid'];
  final pots = db.select(
    "SELECT * FROM pension_pots WHERE user_id=?", [uid]);
  final drawdowns =
      db.select("SELECT * FROM drawdowns WHERE user_id=?", [uid]);

  final rand = Random();
  final results = List<double>.filled(40, 0);

  for (var sim = 0; sim < 500; sim++) {
    double balance = pots.fold<double>(
      0,
      (sum, p) => sum + (p['amount'] as num).toDouble(),
    );

    for (var year = 0; year < 40; year++) {
      balance *= 1 + (0.03 + rand.nextDouble() * 0.04);

      for (final d in drawdowns) {
        balance -= (d['amount'] as num).toDouble();
      }

      results[year] += balance;
    }
  }

  for (var i = 0; i < results.length; i++) {
    results[i] /= 500;
  }

  return Response.ok(
    jsonEncode({'success': true, 'data': results}),
    headers: {'Content-Type': 'application/json'},
  );
}
