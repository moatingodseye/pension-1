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
    ..get('/pension_pots', protected.addHandler(_listPensionPots))
//    ..delete('/pension_pots/<id>', protected.addHandler(_deletePensionPot))
    ..post('/drawdowns', protected.addHandler(_createDrawdown))
    ..get('/drawdowns', protected.addHandler(_listDrawdowns))
//    ..delete('/drawdowns/<id>', protected.addHandler(_deleteDrawdown))
    ..post('/state_pension', protected.addHandler(_setStatePension))
    ..get('/state_pension', protected.addHandler(_getStatePension))
    ..post('/simulate', protected.addHandler(_simulate))
    ..post('/admin/reset_password', protected.addHandler(_adminResetPassword))
    ..post('/admin/lock_user', protected.addHandler(_adminLockUser))
    ..post('/admin/unlock_user', protected.addHandler(_adminUnlockUser))
    ..get('/admin/users', protected.addHandler(_adminUsers));

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

/* ───────────────────── AUTH ROUTES ───────────────────── */

// Future<Response> _register(Request req) async {
//   final body = jsonDecode(await req.readAsString());
//   final hash = BCrypt.hashpw(body['password'], BCrypt.gensalt());

//   try {
//     db.execute(
//       "INSERT INTO users (username, password, dob, is_admin) VALUES (?, ?, ?, 0)",
//       [body['username'], hash, body['dob']],
//     );
//     return Response.ok('Registered');
//   } catch (_) {
//     return Response.internalServerError(
//         body: 'Username already exists');
//   }
// }

Future<Response> _register(Request req) async {
  final body = jsonDecode(await req.readAsString());

  final username = body['username'];
  final password = body['password'];
  final dob = body['dob'];

  if (username == null || password == null || dob == null) {
    return Response(
      400,
      body: jsonEncode({'success': false, 'error': 'Missing fields'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final hash = BCrypt.hashpw(password, BCrypt.gensalt());

  try {
    db.execute(
      "INSERT INTO users (username, password, dob, is_admin) VALUES (?, ?, ?, 0)",
      [username, hash, dob],
    );

    return Response.ok(
      jsonEncode({
        'success': true,
        'message': 'Registered',
        'username': username,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      409,
      body: jsonEncode({'success': false, 'error': 'Username already exists'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// Future<Response> _login(Request req) async {
//   print('_login:${req.headers}');

//   final body = jsonDecode(await req.readAsString());
//   final result = db.select(
//     "SELECT * FROM users WHERE username=?",
//     [body['username']],
//   );

//   if (result.isEmpty) {
//     return Response.forbidden('Invalid credentials');
//   }

//   final user = result.first;

//   if (user['locked'] == 1) {
//     return Response.forbidden('User locked');
//   }

//   if (!BCrypt.checkpw(body['password'], user['password'])) {
//     return Response.forbidden('Invalid credentials');
//   }

//   final jwt = JWT({
//     'id': user['id'],
//     'admin': user['is_admin'] == 1,
//   });

//   return Response.ok(
//     jsonEncode({'token': jwt.sign(SecretKey(jwtSecret))}),
//     headers: {'content-type': 'application/json'},
//   );
// }

Future<Response> _login(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final result = db.select(
    "SELECT * FROM users WHERE username=?",
    [body['username']],
  );

  if (result.isEmpty) {
    return Response(403,
        body: jsonEncode({'success': false, 'error': 'Invalid credentials'}),
        headers: {'Content-Type': 'application/json'});
  }

  final user = result.first;

  if (user['is_admin'] == 0)
    if (user['locked'] == 1) {
      return Response(403,
          body: jsonEncode({'success': false, 'error': 'User locked'}),
          headers: {'Content-Type': 'application/json'});
    }

  if (!BCrypt.checkpw(body['password'], user['password'])) {
    return Response(403,
        body: jsonEncode({'success': false, 'error': 'Invalid credentials'}),
        headers: {'Content-Type': 'application/json'});
  }

  final jwt = JWT({
    'id': user['id'],
    'admin': user['is_admin'] == 1,
  });

  return Response.ok(
    jsonEncode({
      'success': true,
      'token': jwt.sign(SecretKey(jwtSecret)),
      'isAdmin': user['is_admin'] == 1, // <-- add this
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

/* ───────────────────── ADMIN ROUTES ───────────────────── */

// Future<Response> _adminResetPassword(Request req) async {
//   if (req.context['admin'] != true) {
//     return Response.forbidden('Admin only');
//   }

//   final body = jsonDecode(await req.readAsString());
//   final hash =
//       BCrypt.hashpw(body['new_password'], BCrypt.gensalt());

//   db.execute(
//     "UPDATE users SET password=? WHERE id=?",
//     [hash, body['user_id']],
//   );

//   return Response.ok('Password reset');
// }
Future<Response> _adminResetPassword(Request req) async {
  if (req.context['admin'] != true) {
    return Response(
      403,
      body: jsonEncode({'success': false, 'error': 'Admin only'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final body = jsonDecode(await req.readAsString());
  final userId = body['user_id'];
  final newPassword = body['new_password'];

  if (userId == null || newPassword == null) {
    return Response(
      400,
      body: jsonEncode({'success': false, 'error': 'user_id and new_password required'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  db.execute(
    "UPDATE users SET password=? WHERE id=?",
    [hash, userId],
  );

  return Response.ok(
    jsonEncode({'success': true, 'message': 'Password reset'}),
    headers: {'Content-Type': 'application/json'},
  );
}

Future<Response> _adminUsers(Request req) async {
  if (req.context['admin'] != true) {
    return Response(403,
        body: jsonEncode({'success': false, 'error': 'Admin only'}),
        headers: {'Content-Type': 'application/json'});
  }

  final rows = db.select(
      "SELECT id, username, is_admin, locked FROM users");
  final users = rows.map((r) => {
        'id': r['id'],
        'username': r['username'],
        'is_admin': r['is_admin'],
        'locked': r['locked'],
      }).toList();

  return Response.ok(
      jsonEncode({'success': true, 'data': users}),
      headers: {'Content-Type': 'application/json'});
}


// Future<Response> _adminLockUser(Request req) async {
//   if (req.context['admin'] != true) {
//     return Response.forbidden('Admin only');
//   }

//   final body = jsonDecode(await req.readAsString());
//   db.execute(
//     "UPDATE users SET locked=1 WHERE id=?",
//     [body['user_id']],
//   );

//   return Response.ok('User locked');
// }
Future<Response> _adminLockUser(Request req) async {
  if (req.context['admin'] != true) {
    return Response(
      403,
      body: jsonEncode({'success': false, 'error': 'Admin only'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final body = jsonDecode(await req.readAsString());
  final userId = body['user_id'];
  
  if (userId == null) {
    return Response(
      400,
      body: jsonEncode({'success': false, 'error': 'Missing user_id'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  db.execute(
    "UPDATE users SET locked=1 WHERE id=?",
    [userId],
  );

  return Response.ok(
    jsonEncode({'success': true, 'message': 'User locked'}),
    headers: {'Content-Type': 'application/json'},
  );
}

Future<Response> _adminUnlockUser(Request req) async {
  final body = jsonDecode(await req.readAsString());
  if (req.context['admin'] != true) {
    return Response(403,
        body: jsonEncode({'success': false, 'error': 'Admin only'}),
        headers: {'Content-Type': 'application/json'});
  }
  final userId = body['user_id'];
  if (userId == null) {
    return Response(400, body: jsonEncode({'success': false, 'error': 'Missing user_id'}),
      headers: {'Content-Type': 'application/json'});
  }
  db.execute("UPDATE users SET locked = 0 WHERE id = ?", [userId]);

  return Response.ok(jsonEncode({'success': true, 'message': 'User unlocked'}),
      headers: {'Content-Type': 'application/json'});
}

/* ───────────────────── PENSION POTS ───────────────────── */

// Future<Response> _createPensionPot(Request req) async {
//   final body = jsonDecode(await req.readAsString());

//   db.execute(
//     "INSERT INTO pension_pots (user_id, amount, date, interest_rate) VALUES (?, ?, ?, ?)",
//     [
//       req.context['uid'],
//       body['amount'],
//       body['date'],
//       body['interest_rate']
//     ],
//   );

//   return Response.ok('Added');
// }

Future<Response> _createPensionPot(Request req) async {
  try {
    final body = jsonDecode(await req.readAsString());

    final userId = req.context['uid'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({'success': false, 'error': 'Unauthorized'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Validate required fields
    if (body['amount'] == null ||
        body['date'] == null ||
        body['interest_rate'] == null) {
      return Response(
        400,
        body: jsonEncode({'success': false, 'error': 'Missing fields'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    db.execute(
      "INSERT INTO pension_pots (user_id, amount, date, interest_rate) VALUES (?, ?, ?, ?)",
      [userId, body['amount'], body['date'], body['interest_rate']],
    );

    return Response.ok(
      jsonEncode({'success': true, 'message': 'Pension pot created'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'success': false, 'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}


// Future<Response> _listPensionPots(Request req) async {
//   final rows = db.select(
//     "SELECT * FROM pension_pots WHERE user_id=?",
//     [req.context['uid']],
//   );

//   final data =
//       rows.map((r) => Map<String, Object?>.from(r)).toList();

//   return Response.ok(
//     jsonEncode(data),
//     headers: {'content-type': 'application/json'},
//   );
// }

Future<Response> _listPensionPots(Request req) async {
  final rows = db.select(
    "SELECT * FROM pension_pots WHERE user_id=?",
    [req.context['uid']],
  );

  final data = rows.map((r) => {
    'id': r['id'],
    'user_id': r['user_id'],
    'amount': r['amount'],
    'date': r['date'],
    'interest_rate': r['interest_rate'],
  }).toList();

  return Response.ok(
    jsonEncode({'success': true, 'data': data}),
    headers: {'Content-Type': 'application/json'},
  );
}

// Future<Response> _deletePensionPot(Request req, String id) async {
//   db.execute(
//     "DELETE FROM pension_pots WHERE id=? AND user_id=?",
//     [id, req.context['uid']],
//   );
//   return Response.ok('Deleted');
// }

Future<Response> _deletePensionPot(Request req, String id) async {
  try {
    db.execute(
      "DELETE FROM pension_pots WHERE id=? AND user_id=?",
      [id, req.context['uid']],
    );

    return Response.ok(
      jsonEncode({'success': true, 'message': 'Pension pot deleted'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'success': false, 'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/* ───────────────────── DRAWDOWNS ───────────────────── */

// Future<Response> _createDrawdown(Request req) async {
//   final body = jsonDecode(await req.readAsString());

//   db.execute(
//     "INSERT INTO drawdowns (user_id, amount, start_date, end_date, interest_rate) VALUES (?, ?, ?, ?, ?)",
//     [
//       req.context['uid'],
//       body['amount'],
//       body['start_date'],
//       body['end_date'],
//       body['interest_rate']
//     ],
//   );

//   return Response.ok('Added');
// }
Future<Response> _createDrawdown(Request req) async {
  try {
    final body = jsonDecode(await req.readAsString());
    final userId = req.context['uid'];
    db.execute(
      "INSERT INTO drawdowns (user_id, amount, start_date, end_date, interest_rate) VALUES (?, ?, ?, ?, ?)",
      [
        userId,
        body['amount'],
        body['start_date'],
        body['end_date'],
        body['interest_rate']
      ],
    );

    return Response.ok(
      jsonEncode({'success': true, 'message': 'Drawdown created'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'success': false, 'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}


// Future<Response> _listDrawdowns(Request req) async {
//   final rows = db.select(
//     "SELECT * FROM drawdowns WHERE user_id=?",
//     [req.context['uid']],
//   );

//   return Response.ok(
//     jsonEncode(
//         rows.map((r) => Map<String, Object?>.from(r)).toList()),
//     headers: {'content-type': 'application/json'},
//   );
// }

Future<Response> _listDrawdowns(Request req) async {
  final rows = db.select(
    "SELECT * FROM drawdowns WHERE user_id=?",
    [req.context['uid']],
  );

  final data = rows.map((r) => {
    'id': r['id'],
    'user_id': r['user_id'],
    'amount': r['amount'],
    'start_date': r['start_date'],
    'end_date': r['end_date'],
    'interest_rate': r['interest_rate'],
  }).toList();

  return Response.ok(
    jsonEncode({'success': true, 'data': data}),
    headers: {'Content-Type': 'application/json'},
  );
}

// Future<Response> _deleteDrawdown(Request req, String id) async {
//   db.execute(
//     "DELETE FROM drawdowns WHERE id=? AND user_id=?",
//     [id, req.context['uid']],
//   );
//   return Response.ok('Deleted');
// }

Future<Response> _deleteDrawdown(Request req, String id) async {
  try {
    db.execute(
      "DELETE FROM drawdowns WHERE id=? AND user_id=?",
      [id, req.context['uid']],
    );

    return Response.ok(
      jsonEncode({'success': true, 'message': 'Drawdown deleted'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'success': false, 'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/* ───────────────────── STATE PENSION ───────────────────── */

// Future<Response> _setStatePension(Request req) async {
//   final body = jsonDecode(await req.readAsString());

//   db.execute(
//     "DELETE FROM state_pensions WHERE user_id=?",
//     [req.context['uid']],
//   );

//   db.execute(
//     "INSERT INTO state_pensions (user_id, start_age, amount, interest_rate) VALUES (?, ?, ?, ?)",
//     [
//       req.context['uid'],
//       body['start_age'],
//       body['amount'],
//       body['interest_rate']
//     ],
//   );

//   return Response.ok('Saved');
// }

Future<Response> _setStatePension(Request req) async {
  try {
    final body = jsonDecode(await req.readAsString());
    final userId = req.context['uid'];

    db.execute("DELETE FROM state_pensions WHERE user_id=?", [userId]);
    db.execute(
      "INSERT INTO state_pensions (user_id, start_age, amount, interest_rate) VALUES (?, ?, ?, ?)",
      [userId, body['start_age'], body['amount'], body['interest_rate']],
    );

    return Response.ok(
      jsonEncode({'success': true, 'message': 'State pension saved'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'success': false, 'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// Future<Response> _getStatePension(Request req) async {
//   final rows = db.select(
//     "SELECT * FROM state_pensions WHERE user_id=?",
//     [req.context['uid']],
//   );

//   return Response.ok(
//     jsonEncode(
//       rows.isEmpty ? {} : Map<String, Object?>.from(rows.first),
//     ),
//     headers: {'content-type': 'application/json'},
//   );
// }
Future<Response> _getStatePension(Request req) async {
  final rows = db.select(
    "SELECT * FROM state_pensions WHERE user_id=?",
    [req.context['uid']],
  );

  if (rows.isEmpty) {
    return Response.ok(
      jsonEncode({'success': true, 'data': null}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final r = rows.first;
  final data = {
    'id': r['id'],
    'user_id': r['user_id'],
    'start_age': r['start_age'],
    'amount': r['amount'],
    'interest_rate': r['interest_rate'],
  };

  return Response.ok(
    jsonEncode({'success': true, 'data': data}),
    headers: {'Content-Type': 'application/json'},
  );
}

/* ───────────────────── SIMULATION ───────────────────── */

// Future<Response> _simulate(Request req) async {
//   final uid = req.context['uid'];

//   final pots =
//       db.select("SELECT * FROM pension_pots WHERE user_id=?", [uid]);
//   final drawdowns =
//       db.select("SELECT * FROM drawdowns WHERE user_id=?", [uid]);

//   final rand = Random();
//   final results = List<double>.filled(40, 0);

//   for (var sim = 0; sim < 500; sim++) {
//     double balance = pots.fold<double>(
//       0,
//       (sum, p) => sum + (p['amount'] as num).toDouble(),
//     );

//     for (var year = 0; year < 40; year++) {
//       balance *= 1 + (0.03 + rand.nextDouble() * 0.04);

//       for (final d in drawdowns) {
//         balance -= (d['amount'] as num).toDouble();
//       }

//       results[year] += balance;
//     }
//   }

//   for (var i = 0; i < results.length; i++) {
//     results[i] /= 500;
//   }

//   return Response.ok(
//     jsonEncode(results),
//     headers: {'content-type': 'application/json'},
//   );
// }

Future<Response> _simulate(Request req) async {
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
