import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/middleware/auth_middleware.dart';
import 'package:kanban_api/middleware/cors_middleware.dart';

Handler middleware(Handler handler) {
  // No Dart Frog, o último `.use()` processa a requisição primeiro e a resposta por último.
  // CORS precisa ser o mais externo para: (1) responder OPTIONS antes da auth e
  // (2) incluir os headers mesmo quando a auth rejeita a requisição (401/403).
  return handler
      .use(requestLogger())
      .use(authMiddleware())
      .use(corsMiddleware());
}
