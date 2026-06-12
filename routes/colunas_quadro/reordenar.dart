import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/compartilhado/rota_modulo_util.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';
import 'package:kanban_api/modulos/colunas_quadro/coluna_quadro_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return RotaModuloUtil.metodoNaoPermitido();
  }

  return getIt<ColunaQuadroController>().reordenar(context);
}
