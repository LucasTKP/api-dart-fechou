import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/usuarios/usuario_schema.dart';
import 'package:kanban_api/modulos/usuarios/usuario_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class UsuarioController extends ControllerBase {
  UsuarioController(this._service);

  final UsuarioService _service;

  Future<Response> buscarPorId(RequestContext context, String id) {
    return executar(() async {
      final usuario = await _service.buscarPorId(usuarioId: id);
      if (usuario == null) {
        return RespostaJsonUtil.erro(
          mensagem: 'Usuário não encontrado.',
          statusCode: HttpStatus.notFound,
        );
      }
      return RespostaJsonUtil.sucesso(dados: usuario.toMap());
    });
  }

  Future<Response> cadastrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(UsuarioSchema.cadastrar, corpo);

      final usuarioId = context.read<ContextoUsuario>().id;
      final usuario = await _service.cadastrar(
        usuarioId: usuarioId,
        cadastrarUsuarioEntrada: dados,
      );
      return RespostaJsonUtil.sucesso(
        dados: usuario.toMap(),
        statusCode: HttpStatus.created,
      );
    });
  }
}
