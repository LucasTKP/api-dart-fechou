import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/contexto_usuario.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/whatsapp/whatsapp_schema.dart';
import 'package:kanban_api/modulos/whatsapp/whatsapp_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class WhatsappController extends ControllerBase {
  WhatsappController(this._service);

  final WhatsappService _service;

  Future<Response> status(RequestContext context) {
    return executar(() async {
      final dados = validar(WhatsappSchema.sessao, queryParams(context));
      final usuarioId = context.read<ContextoUsuario>().id;

      final status = await _service.status(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );

      return RespostaJsonUtil.sucesso(dados: status);
    });
  }

  Future<Response> conectar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(WhatsappSchema.sessao, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;

      final status = await _service.conectar(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );

      return RespostaJsonUtil.sucesso(dados: status);
    });
  }

  Future<Response> qrCode(RequestContext context) {
    return executar(() async {
      final dados = validar(WhatsappSchema.sessao, queryParams(context));
      final usuarioId = context.read<ContextoUsuario>().id;

      final qrcode = await _service.qrCode(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );

      return Response.bytes(
        body: qrcode.bytes,
        headers: {HttpHeaders.contentTypeHeader: qrcode.contentType},
      );
    });
  }

  Future<Response> encerrar(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(WhatsappSchema.sessao, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;

      await _service.encerrar(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );

      return Response(statusCode: HttpStatus.noContent);
    });
  }

  Future<Response> limparDados(RequestContext context) {
    return executar(() async {
      final corpo = await context.request.json();
      final dados = validar(WhatsappSchema.sessao, corpo);
      final usuarioId = context.read<ContextoUsuario>().id;

      await _service.limparDados(
        usuarioId: usuarioId,
        organizacaoId: dados.organizacaoId,
      );

      return Response(statusCode: HttpStatus.noContent);
    });
  }
}
