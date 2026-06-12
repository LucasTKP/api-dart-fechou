import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_schema.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class OrganizacaoController extends ControllerBase {
  OrganizacaoController(this._service);

  final OrganizacaoService _service;

  Future<Response> listar(RequestContext context) {
    return executar(() async {
      final usuarioId = context.read<ContextoUsuario>().id;
      final organizacoes = await _service.listar(usuarioId: usuarioId);
      return RespostaJsonUtil.sucessoLista(
        dados: organizacoes.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(OrganizacaoSchema.cadastrar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final organizacao = await _service.cadastrar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: organizacao.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }

  Future<Response> buscarPorId(RequestContext context, String id) {
    return executar(() async {
      final usuarioId = context.read<ContextoUsuario>().id;
      final organizacao = await _service.buscarPorId(
        usuarioId: usuarioId,
        id: id,
      );
      return RespostaJsonUtil.sucesso(dados: organizacao.toMap());
    });
  }

  Future<Response> atualizar(RequestContext context, String id) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(OrganizacaoSchema.atualizar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final organizacao = await _service.atualizar(
        usuarioId: usuarioId,
        id: id,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(dados: organizacao.toMap());
    });
  }

  Future<Response> listarMembros(RequestContext context) {
    return executar(() async {
      final dados = validar(
        OrganizacaoSchema.listarMembros,
        queryParams(context),
      );
      final usuarioId = context.read<ContextoUsuario>().id;
      final membros = await _service.listarMembros(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: membros.map((e) => e.toMap()).toList(),
      );
    });
  }
}
