import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
//import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

final db = sqlite3.open('pension.db');
const jwtSecret = 'local-secret';

// an attempt using logrequests as an example, causes an infinite loop
// Middleware cors() =>
//     (innerHandler) {
//       return (request) {
//         print('start:${request.method}');

//         if (request.method == 'OPTIONS') {
//           return Response.ok(
//             '',
//             headers: {
//               'Access-Control-Allow-Origin': '*',
//               'Access-Control-Allow-Methods': 'POST, GET, PUT, OPTIONS, DELETE',
//               'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
//               'Access-Control-Max-Age': '86400', // cache preflight for 24h
//             },
//           );
//         }

//         return Future.sync(() => innerHandler(request)).then((response) {
//           print('response:${response.statusCode}');
//           return response;
//         }, onError: (Object error, StackTrace stackTrace) {
//           print('error:${error} ${stackTrace}');

//           throw error;
//         });
//       };
//     };

Response preflightHandler(Request request) {
  return Response.ok('',
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400', // Cache preflight for 24 hours
    },
  );
}   

final monitor = createMiddleware(
  requestHandler: (Request request) {
    // Run before request is handled
    print('Before request-1:${request.method}');
    // if (request.method == 'OPTIONS') {
    //     return preflightHandler(request);
    // }
    print('Before request-2:${request.method}');
    return null; // Continue to next handler
  },
  responseHandler: (Response response) {
    // Run after response is generated
    print('After response:${response.statusCode}');
    return response.change(headers: {'X-Custom': 'value'});
  },
);    

void main() async {
  _initDb();

// final cors = createMiddleware(
//   requestHandler: (Request request) {
//     print('cors:request:${request.method}');
//     if (request.method == 'OPTIONS') {
//       return Response.ok(null, headers: {
//         'Access-Control-Allow-Origin': '*',
//         'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//         'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
//       });
//     }
//     return null; // Continue
//   },
//   responseHandler: (Response response) {
//     print('cors:response:${response.statusCode}');
//     return response.change(headers: {
//       'Access-Control-Allow-Origin': '*',
//       'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//       'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
//     });
//   },
// );

// Middleware requestcors() {
//   return (Handler inner) {
//     return (Request req) async {
//       print('cors:request:${req.method}');
//       if (req.method=='OPTIONS') {
//         return Response.ok(null, headers: {
//           'Access-Control-Allow-Origin': '*',
//           'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//           'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
//         });
//       } else
//         return await inner(req);
//       // final resp = await inner(req);
//       // print('cors:response:${resp.statusCode}');
//       // return resp.change(headers: {
//       //   'Access-Control-Allow-Origin': '*',
//       //   'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//       //   'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
//       // });
//     };
//   };
// }   

// Middleware responsecors() {
//   return (Handler inner) {
//     return (Request req) async {
//       print('cors:request:${req.method}');
//       final resp = await inner(req);
//       print('cors:response:${resp.statusCode}');
//       return resp.change(headers: {
//         'Access-Control-Allow-Origin': '*',
//         'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//         'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
//       });
//     };
//   };
// }   

  // Public routes
  final app = Router();
  final public = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(monitor)
    .addMiddleware(corsHeaders())
    .addHandler(app);
  final protected = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(monitor)
    .addMiddleware(corsHeaders())
    .addMiddleware(authMiddleware());
  
  app
    ..post('/register', _register)
    ..post('/login', _login)
    ..post('/pension_pots',   protected.addHandler(_createPensionPot))
    ..get('/pension_pots', _listPensionPots)
    ..delete('/pension_pots/<id>', _deletePensionPot)
    ..post('/drawdowns', _createDrawdown)
    ..get('/drawdowns', _listDrawdowns)
    ..delete('/drawdowns/<id>', _deleteDrawdown)
    ..post('/state_pension', _setStatePension)
    ..get('/state_pension', _getStatePension)
    ..post('/simulate', _simulate)
    ..post('/admin/reset_password', _adminResetPassword)
    ..post('/admin/lock_user', _adminLockUser);

  final server = await serve(public, InternetAddress.anyIPv4, 8080);
  print('Server running on IP ${server.address.address}:${server.port}');
}

/* ───────────────────────── DATABASE ───────────────────────── */

void _initDb() {
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password TEXT,
      dob TEXT,
      is_admin INTEGER,
      locked INTEGER DEFAULT 0
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS pension_pots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      amount REAL,
      date TEXT,
      interest_rate REAL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS drawdowns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      amount REAL,
      start_date TEXT,
      end_date TEXT,
      interest_rate REAL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS state_pensions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      start_age INTEGER,
      amount REAL,
      interest_rate REAL
    )
  ''');

  final admin =
      db.select("SELECT * FROM users WHERE username='admin'");
  if (admin.isEmpty) {
    final hash = BCrypt.hashpw('admin', BCrypt.gensalt());
    db.execute(
      "INSERT INTO users (username, password, dob, is_admin) VALUES (?, ?, ?, 1)",
      ['admin', hash, '1970-01-01'],
    );
  }
}

/* ───────────────────── AUTH MIDDLEWARE ───────────────────── */

Middleware authMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      final auth = req.headers['authorization'];
      if (auth == null || !auth.startsWith('Bearer ')) {
        return Response.forbidden('Missing token');
      }

      try {
        final token = auth.substring(7);
        final jwt = JWT.verify(token, SecretKey(jwtSecret));

        return inner(
          req.change(
            context: {
              'uid': jwt.payload['id'],
              'admin': jwt.payload['admin'],
            },
          ),
        );
      } catch (_) {
        return Response.forbidden('Invalid token');
      }
    };
  };
}

// Middleware cors() {
//   return (Handler innerHandler) {
//     return (Request request) async {
//       print('cors:request:${request.headers}');
//       // Handle OPTIONS request to prevent it from going further
//       if (request.method == 'OPTIONS') {
//         return Response.ok(
//           '',
//           headers: {
//             'Access-Control-Allow-Origin': '*',
//             'Access-Control-Allow-Methods': 'POST, GET, PUT, OPTIONS, DELETE',
//             'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
//             'Access-Control-Max-Age': '86400', // cache preflight for 24h
//           },
//         );
//       }

//       // Allow the request to proceed to the next handler (non-OPTIONS)
//       final response = await innerHandler(request);
//       print('cors:response:${response.headers}');

//       // Add CORS headers to the response
//       return response.change(headers: {
//         ...response.headers,
//         'Access-Control-Allow-Origin': '*',
//         'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
//         'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//       });
//     };
//   };
// }

/* ───────────────────── AUTH ROUTES ───────────────────── */

Future<Response> _register(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final hash = BCrypt.hashpw(body['password'], BCrypt.gensalt());

  try {
    db.execute(
      "INSERT INTO users (username, password, dob, is_admin) VALUES (?, ?, ?, 0)",
      [body['username'], hash, body['dob']],
    );
    return Response.ok('Registered');
  } catch (_) {
    return Response.internalServerError(
        body: 'Username already exists');
  }
}

Future<Response> _login(Request req) async {
  print('_login:${req.headers}');

  final body = jsonDecode(await req.readAsString());
  final result = db.select(
    "SELECT * FROM users WHERE username=?",
    [body['username']],
  );

  if (result.isEmpty) {
    return Response.forbidden('Invalid credentials');
  }

  final user = result.first;

  if (user['locked'] == 1) {
    return Response.forbidden('User locked');
  }

  if (!BCrypt.checkpw(body['password'], user['password'])) {
    return Response.forbidden('Invalid credentials');
  }

  final jwt = JWT({
    'id': user['id'],
    'admin': user['is_admin'] == 1,
  });

  return Response.ok(
    jsonEncode({'token': jwt.sign(SecretKey(jwtSecret))}),
    headers: {'content-type': 'application/json'},
  );
}

/* ───────────────────── ADMIN ROUTES ───────────────────── */

Future<Response> _adminResetPassword(Request req) async {
  if (req.context['admin'] != true) {
    return Response.forbidden('Admin only');
  }

  final body = jsonDecode(await req.readAsString());
  final hash =
      BCrypt.hashpw(body['new_password'], BCrypt.gensalt());

  db.execute(
    "UPDATE users SET password=? WHERE id=?",
    [hash, body['user_id']],
  );

  return Response.ok('Password reset');
}

Future<Response> _adminLockUser(Request req) async {
  if (req.context['admin'] != true) {
    return Response.forbidden('Admin only');
  }

  final body = jsonDecode(await req.readAsString());
  db.execute(
    "UPDATE users SET locked=1 WHERE id=?",
    [body['user_id']],
  );

  return Response.ok('User locked');
}

/* ───────────────────── PENSION POTS ───────────────────── */

Future<Response> _createPensionPot(Request req) async {
  final body = jsonDecode(await req.readAsString());

  db.execute(
    "INSERT INTO pension_pots (user_id, amount, date, interest_rate) VALUES (?, ?, ?, ?)",
    [
      req.context['uid'],
      body['amount'],
      body['date'],
      body['interest_rate']
    ],
  );

  return Response.ok('Added');
}

Future<Response> _listPensionPots(Request req) async {
  final rows = db.select(
    "SELECT * FROM pension_pots WHERE user_id=?",
    [req.context['uid']],
  );

  final data =
      rows.map((r) => Map<String, Object?>.from(r)).toList();

  return Response.ok(
    jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _deletePensionPot(Request req, String id) async {
  db.execute(
    "DELETE FROM pension_pots WHERE id=? AND user_id=?",
    [id, req.context['uid']],
  );
  return Response.ok('Deleted');
}

/* ───────────────────── DRAWDOWNS ───────────────────── */

Future<Response> _createDrawdown(Request req) async {
  final body = jsonDecode(await req.readAsString());

  db.execute(
    "INSERT INTO drawdowns (user_id, amount, start_date, end_date, interest_rate) VALUES (?, ?, ?, ?, ?)",
    [
      req.context['uid'],
      body['amount'],
      body['start_date'],
      body['end_date'],
      body['interest_rate']
    ],
  );

  return Response.ok('Added');
}

Future<Response> _listDrawdowns(Request req) async {
  final rows = db.select(
    "SELECT * FROM drawdowns WHERE user_id=?",
    [req.context['uid']],
  );

  return Response.ok(
    jsonEncode(
        rows.map((r) => Map<String, Object?>.from(r)).toList()),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _deleteDrawdown(Request req, String id) async {
  db.execute(
    "DELETE FROM drawdowns WHERE id=? AND user_id=?",
    [id, req.context['uid']],
  );
  return Response.ok('Deleted');
}

/* ───────────────────── STATE PENSION ───────────────────── */

Future<Response> _setStatePension(Request req) async {
  final body = jsonDecode(await req.readAsString());

  db.execute(
    "DELETE FROM state_pensions WHERE user_id=?",
    [req.context['uid']],
  );

  db.execute(
    "INSERT INTO state_pensions (user_id, start_age, amount, interest_rate) VALUES (?, ?, ?, ?)",
    [
      req.context['uid'],
      body['start_age'],
      body['amount'],
      body['interest_rate']
    ],
  );

  return Response.ok('Saved');
}

Future<Response> _getStatePension(Request req) async {
  final rows = db.select(
    "SELECT * FROM state_pensions WHERE user_id=?",
    [req.context['uid']],
  );

  return Response.ok(
    jsonEncode(
      rows.isEmpty ? {} : Map<String, Object?>.from(rows.first),
    ),
    headers: {'content-type': 'application/json'},
  );
}

/* ───────────────────── SIMULATION ───────────────────── */

Future<Response> _simulate(Request req) async {
  final uid = req.context['uid'];

  final pots =
      db.select("SELECT * FROM pension_pots WHERE user_id=?", [uid]);
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
    jsonEncode(results),
    headers: {'content-type': 'application/json'},
  );
}
