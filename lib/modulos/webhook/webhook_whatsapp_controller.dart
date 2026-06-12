import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/controller_base.dart';
import 'package:kanban_api/modulos/webhook/webhook_whatsapp_service.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

class WebhookWhatsappController extends ControllerBase {
  WebhookWhatsappController(this._service);

  final WebhookWhatsappService _service;

  Future<Response> processar(RequestContext context) {
    return executar(() async {
      final payload = await context.request.json() as Map<String, dynamic>;
      final resultado = await _service.processar(payload);

      return RespostaJsonUtil.sucesso(dados: resultado.toMap());
    });
  }
}
