import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/config/ambiente.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

/// Valida o JWT do Supabase Auth e injeta [ContextoUsuario].
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
        final resposta = await Ambiente.supabase.auth.getUser(jwt);
        final usuario = resposta.user;

        if (usuario == null) {
          return RespostaJsonUtil.erro(
            mensagem: 'Token de autenticação inválido.',
            statusCode: HttpStatus.unauthorized,
          );
        }

        return handler(
          context.provide<ContextoUsuario>(
            () => ContextoUsuario(id: usuario.id),
          ),
        );
      } catch (_) {
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
