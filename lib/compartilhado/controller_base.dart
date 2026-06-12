import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
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
    } on NaoAutenticadoException catch (erro) {
      return RespostaJsonUtil.erro(
        mensagem: erro.mensagem,
        statusCode: HttpStatus.unauthorized,
      );
    } on AcessoNegadoException catch (erro) {
      return RespostaJsonUtil.erro(
        mensagem: erro.mensagem,
        statusCode: HttpStatus.forbidden,
      );
    } on RecursoNaoEncontradoException catch (erro) {
      return RespostaJsonUtil.erro(
        mensagem: erro.mensagem,
        statusCode: HttpStatus.notFound,
      );
    } on ValidacaoException catch (erro) {
      return RespostaJsonUtil.erro(mensagem: erro.mensagem);
    } on NaoImplementadoException catch (erro) {
      return RespostaJsonUtil.erro(
        mensagem: erro.mensagem,
        statusCode: HttpStatus.notImplemented,
      );
    } on FormatException {
      return RespostaJsonUtil.erro(mensagem: 'Corpo da requisição inválido.');
    } catch (erro, stackTrace) {
      stderr
        ..writeln('[ERRO INTERNO] $erro')
        ..writeln(stackTrace);
      return RespostaJsonUtil.erro(
        mensagem: 'Erro interno: $erro',
        statusCode: HttpStatus.internalServerError,
      );
    }
  }
}
