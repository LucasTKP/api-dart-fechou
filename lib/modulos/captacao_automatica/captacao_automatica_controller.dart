import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/captacao_automatica/captacao_automatica_schema.dart';
import 'package:kanban_api/modulos/captacao_automatica/captacao_automatica_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class CaptacaoAutomaticaController extends ControllerBase {
  CaptacaoAutomaticaController(this._service);

  final CaptacaoAutomaticaService _service;

  Future<Response> listar(RequestContext context) {
    return executar(() async {
      final dados = validar(
        CaptacaoAutomaticaSchema.listar,
        queryParams(context),
      );
      final usuarioId = context.read<ContextoUsuario>().id;
      final regras = await _service.listar(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: regras.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(CaptacaoAutomaticaSchema.cadastrar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final regra = await _service.cadastrar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: regra.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }

  Future<Response> atualizar(RequestContext context, String id) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(CaptacaoAutomaticaSchema.atualizar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final regra = await _service.atualizar(
        usuarioId: usuarioId,
        id: id,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(dados: regra.toMap());
    });
  }

  Future<Response> excluir(RequestContext context, String id) {
    return executar(() async {
      final usuarioId = context.read<ContextoUsuario>().id;
      await _service.excluir(usuarioId: usuarioId, id: id);
      return Response(statusCode: HttpStatus.noContent);
    });
  }
}
