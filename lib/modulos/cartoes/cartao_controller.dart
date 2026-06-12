import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/cartoes/cartao_schema.dart';
import 'package:kanban_api/modulos/cartoes/cartao_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class CartaoController extends ControllerBase {
  CartaoController(this._service);

  final CartaoService _service;

  Future<Response> listar(RequestContext context) {
    return executar(() async {
      final dados = validar(CartaoSchema.listar, queryParams(context));
      final usuarioId = context.read<ContextoUsuario>().id;
      final cartoes = await _service.listarPorQuadro(
        usuarioId: usuarioId,
        quadroId: dados.quadroId,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: cartoes.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(CartaoSchema.cadastrar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final cartao = await _service.cadastrar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: cartao.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }

  Future<Response> atualizar(RequestContext context, String id) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(CartaoSchema.atualizar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final cartao = await _service.atualizar(
        usuarioId: usuarioId,
        id: id,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(dados: cartao.toMap());
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
