import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

const _cabecalhosCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

/// Permite chamadas da kanban-web (Flutter Web) à API em outra origem.
Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(statusCode: HttpStatus.noContent, headers: _cabecalhosCors);
      }

      final resposta = await handler(context);

      return resposta.copyWith(
        headers: {
          ...resposta.headers,
          ..._cabecalhosCors,
        },
      );
    };
  };
}
