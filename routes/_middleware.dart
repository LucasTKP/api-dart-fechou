import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/middleware/auth_middleware.dart';
import 'package:kanban_api/middleware/cors_middleware.dart';

Handler middleware(Handler handler) {
  // No Dart Frog, o último `.use()` é o middleware mais externo (roda primeiro).
  // CORS precisa ficar por fora para responder ao preflight (OPTIONS) antes da auth.
  return handler
      .use(corsMiddleware())
      .use(authMiddleware())
      .use(requestLogger());
}
