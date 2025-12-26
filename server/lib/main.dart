import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'db.dart';
import 'auth.dart';
import 'user.dart';
import 'pension.dart';
import 'drawdown.dart';
import 'state_pension.dart';

void main() async {
  // Initialize the database and run migrations
  initDb();

  final pub = Router();
  final prot = Router();

  // Public pipeline (no auth)
  final public = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(pub);

  // Protected pipeline (with auth)
  final protected = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(authMiddleware())
      .addHandler(prot);

  final cas = Cascade().add(public).add(protected).handler;

  // --- Public routes ---
  pub
    ..post('/register', register)
    ..post('/login', login);

  // --- Protected routes ---
  prot
    ..post('/pension_pots', createPensionPot)
    ..get('/pension_pots', listPensionPots)
    ..delete('/pension_pots/<id>', deletePensionPot)
    ..put('/pension_pots/<id>', updatePensionPot)

    ..post('/drawdowns', createDrawdown)
    ..get('/drawdowns', listDrawdowns)

    ..post('/state_pension', createStatePension)
    ..get('/state_pension', listStatePensions)

    ..get('/users', getUsers)
    ..post('/lock_user', lockUser)
    ..post('/unlock_user', unlockUser)
    ..post('/reset_password', resetPassword);

  final server = await serve(cas, InternetAddress.anyIPv4, 8080);
  print('Server running on ${server.address.address}:${server.port}');
}
