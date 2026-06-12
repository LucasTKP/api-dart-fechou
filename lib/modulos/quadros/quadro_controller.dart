import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/quadros/quadro_schema.dart';
import 'package:kanban_api/modulos/quadros/quadro_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class QuadroController extends ControllerBase {
  QuadroController(this._service);

  final QuadroService _service;

  Future<Response> listar(RequestContext context) {
    return executar(() async {
      final dados = validar(QuadroSchema.listar, queryParams(context));
      final usuarioId = context.read<ContextoUsuario>().id;
      final quadros = await _service.listar(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );
      return RespostaJsonUtil.sucessoLista(
        dados: quadros.map((e) => e.toMap()).toList(),
      );
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(QuadroSchema.cadastrar, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;
      final quadro = await _service.cadastrar(
        usuarioId: usuarioId,
        entrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: quadro.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }
}
