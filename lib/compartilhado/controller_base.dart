import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/utils/log_api_util.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';
import 'package:zard/zard.dart';

/// Tratamento padrão de exceções dos controllers.
abstract class ControllerBase {
  T validar<T>(Schema<T> schema, dynamic dados) {
    try {
      return schema.parse(dados);
    } on ZardError catch (erro) {
      throw ValidacaoException(erro.messages);
    }
  }

  Map<String, String> queryParams(RequestContext context) {
    return {...context.request.uri.queryParameters}
      ..removeWhere((_, valor) => valor.isEmpty);
  }

  Future<Response> executar(Future<Response> Function() acao) async {
    try {
      return await acao();
    } on ExcecaoApi catch (erro) {
      return _respostaExcecaoApi(erro);
    } on FormatException catch (erro) {
      LogApiUtil.erro(
        tipo: 'Requisição inválida',
        erro: erro,
        statusCode: HttpStatus.badRequest,
      );
      return RespostaJsonUtil.erro(mensagem: 'Corpo da requisição inválido.');
    } catch (erro, stackTrace) {
      LogApiUtil.erro(
        tipo: 'Erro interno',
        erro: erro,
        stackTrace: stackTrace,
        statusCode: HttpStatus.internalServerError,
      );
      return RespostaJsonUtil.erro(
        mensagem: 'Erro interno: $erro',
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  Response _respostaExcecaoApi(ExcecaoApi erro) {
    final (tipo, statusCode) = switch (erro) {
      NaoAutenticadoException() => (
          'Não autenticado',
          HttpStatus.unauthorized,
        ),
      AcessoNegadoException() => ('Acesso negado', HttpStatus.forbidden),
      RecursoNaoEncontradoException() => (
          'Recurso não encontrado',
          HttpStatus.notFound,
        ),
      ValidacaoException() => ('Validação', HttpStatus.badRequest),
      NaoImplementadoException() => (
          'Não implementado',
          HttpStatus.notImplemented,
        ),
    };

    LogApiUtil.erro(
      tipo: tipo,
      erro: erro,
      statusCode: statusCode,
    );

    return RespostaJsonUtil.erro(
      mensagem: erro.mensagem,
      statusCode: statusCode,
    );
  }
}
