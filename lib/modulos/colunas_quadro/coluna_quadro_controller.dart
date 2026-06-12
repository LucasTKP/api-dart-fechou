import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/colunas_quadro/coluna_quadro_schema.dart';
import 'package:kanban_api/modulos/colunas_quadro/coluna_quadro_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class ColunaQuadroController extends ControllerBase {
  ColunaQuadroController(this._service);

  final ColunaQuadroService _service;

  Future<Response> listar(RequestContext context) {
    return executar(() async {
      final dados = validar(ColunaQuadroSchema.listar, queryParams(context));
      final usuarioId = context.read<ContextoUsuario>().id;
      final colunas = await _service.listar(
        usuarioId: usuarioId,
        quadroId: dados.quadroId,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: colunas.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(ColunaQuadroSchema.cadastrar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final coluna = await _service.cadastrar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: coluna.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }

  Future<Response> atualizar(RequestContext context, String id) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(ColunaQuadroSchema.atualizar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final coluna = await _service.atualizar(
        usuarioId: usuarioId,
        id: id,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(dados: coluna.toMap());
    });
  }

  Future<Response> reordenar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(ColunaQuadroSchema.reordenar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      await _service.reordenar(usuarioId: usuarioId, entrada: dados);
      return Response(statusCode: HttpStatus.noContent);
    });
  }

  Future<Response> excluir(RequestContext context, String id) {
    return executar(() async {
      final colunaDestinoId = queryParams(context)['coluna_destino_id'];
      final usuarioId = context.read<ContextoUsuario>().id;
      await _service.excluir(
        usuarioId: usuarioId,
        id: id,
        colunaDestinoId: colunaDestinoId,
      );
      return Response(statusCode: HttpStatus.noContent);
    });
  }
}
