import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/validador_jwt_supabase.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/utils/log_api_util.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

/// Valida o JWT do Supabase Auth localmente e injeta [ContextoUsuario].
///
/// Rotas públicas (`/` e `/webhook/*`) não exigem autenticação.
Middleware authMiddleware() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return handler(context);
      }

      final caminho = context.request.uri.path;

      if (_rotaPublica(caminho)) {
        return handler(context);
      }

      final authorization = context.request.headers['Authorization'];
      if (authorization == null || !authorization.startsWith('Bearer ')) {
        return RespostaJsonUtil.erro(
          mensagem: 'Token de autenticação ausente.',
          statusCode: HttpStatus.unauthorized,
        );
      }

      final jwt = authorization.substring('Bearer '.length).trim();
      if (jwt.isEmpty) {
        return RespostaJsonUtil.erro(
          mensagem: 'Token de autenticação inválido.',
          statusCode: HttpStatus.unauthorized,
        );
      }

      try {
        final usuarioId =
            getIt<ValidadorJwtSupabase>().extrairUsuarioId(jwt);

        if (usuarioId == null) {
          return RespostaJsonUtil.erro(
            mensagem: 'Token de autenticação inválido.',
            statusCode: HttpStatus.unauthorized,
          );
        }

        return handler(
          context.provide<ContextoUsuario>(
            () => ContextoUsuario(id: usuarioId),
          ),
        );
      } catch (erro, stackTrace) {
        LogApiUtil.erro(
          tipo: 'Autenticação',
          erro: erro,
          stackTrace: stackTrace,
          statusCode: HttpStatus.unauthorized,
        );
        return RespostaJsonUtil.erro(
          mensagem: 'Token de autenticação inválido.',
          statusCode: HttpStatus.unauthorized,
        );
      }
    };
  };
}

bool _rotaPublica(String caminho) {
  if (caminho == '/') return true;
  return caminho.startsWith('/webhook');
}
