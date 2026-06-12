import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/rota_modulo_util.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/modulos/cartoes/cartao_controller.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final controller = getIt<CartaoController>();

  return switch (context.request.method) {
    HttpMethod.put => controller.atualizar(context, id),
    HttpMethod.delete => controller.excluir(context, id),
    _ => RotaModuloUtil.metodoNaoPermitido(),
  };
}
