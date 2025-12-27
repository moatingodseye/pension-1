import 'package:shelf/shelf.dart';

final monitor1 = createMiddleware(
  requestHandler: (Request request) {
    print('Public Request:${request.method}');
    return null; // Continue to next handler
  },
  responseHandler: (Response response) {
    // Run after response is generated
    print('Public Response:${response.statusCode}');
    return response.change(headers: {'X-Custom': 'value'});
  },
);   

final monitor2 = createMiddleware(
  requestHandler: (Request request) {
    print('Protected Request:${request.method}');
    return null; // Continue to next handler
  },
  responseHandler: (Response response) {
    // Run after response is generated
    print('Protected Response:${response.statusCode}');
    return response.change(headers: {'X-Custom': 'value'});
  },
);   