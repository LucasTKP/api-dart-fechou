import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/rota_modulo_util.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/modulos/whatsapp/whatsapp_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = getIt<WhatsappController>();

  return switch (context.request.method) {
    HttpMethod.get => controller.qrCode(context),
    _ => RotaModuloUtil.metodoNaoPermitido(),
  };
}
