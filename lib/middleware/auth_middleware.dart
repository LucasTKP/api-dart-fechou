import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/utils/log_api_util.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

const _cabecalhosCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

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
          headers: _cabecalhosCors,
        );
      }

      final jwt = authorization.substring('Bearer '.length).trim();
      if (jwt.isEmpty) {
        return RespostaJsonUtil.erro(
          mensagem: 'Token de autenticação inválido.',
          statusCode: HttpStatus.unauthorized,
          headers: _cabecalhosCors,
        );
      }

      try {
        final resposta = await getIt<SupabaseClient>().auth.getUser(jwt);
        final usuarioId = resposta.user?.id;

        if (usuarioId == null || usuarioId.isEmpty) {
          return RespostaJsonUtil.erro(
            mensagem: 'Token de autenticação inválido.',
            statusCode: HttpStatus.unauthorized,
            headers: _cabecalhosCors,
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
          headers: _cabecalhosCors,
        );
      }
    };
  };
}

bool _rotaPublica(String caminho) {
  if (caminho == '/') return true;
  return caminho.startsWith('/webhook');
}
