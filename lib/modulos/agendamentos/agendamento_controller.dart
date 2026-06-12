import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/agendamentos/agendamento_schema.dart';
import 'package:kanban_api/modulos/agendamentos/agendamento_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class AgendamentoController extends ControllerBase {
  AgendamentoController(this._service);

  final AgendamentoService _service;

  Future<Response> listar(RequestContext context) {
    return executar(() async {
      final dados = validar(AgendamentoSchema.listar, queryParams(context));
      final usuarioId = context.read<ContextoUsuario>().id;
      final agendamentos = await _service.listar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: agendamentos.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> listarPorCartao(RequestContext context) {
    return executar(() async {
      final dados = validar(
        AgendamentoSchema.listarPorCartao,
        queryParams(context),
      );
      final usuarioId = context.read<ContextoUsuario>().id;
      final agendamentos = await _service.listarPorCartao(
        usuarioId: usuarioId,
        cartaoId: dados.cartaoId,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: agendamentos.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(AgendamentoSchema.cadastrar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final agendamento = await _service.cadastrar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: agendamento.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }

  Future<Response> atualizar(RequestContext context, String id) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(AgendamentoSchema.atualizar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final agendamento = await _service.atualizar(
        usuarioId: usuarioId,
        id: id,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(dados: agendamento.toMap());
    });
  }

  Future<Response> cancelar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(AgendamentoSchema.cancelar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final agendamento = await _service.cancelar(
        usuarioId: usuarioId,
        id: dados.id,
      );
      return RespostaJsonUtil.sucesso(dados: agendamento.toMap());
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
