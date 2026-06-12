import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/rota_modulo_util.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return RotaModuloUtil.metodoNaoPermitido();
  }

  return getIt<OrganizacaoController>().listarMembros(context);
}
