import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/rota_modulo_util.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = getIt<OrganizacaoController>();

  return switch (context.request.method) {
    HttpMethod.get => controller.listar(context),
    HttpMethod.post => controller.cadastrar(context),
    _ => RotaModuloUtil.metodoNaoPermitido(),
  };
}
