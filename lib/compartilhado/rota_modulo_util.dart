import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/utils/resposta_json_util.dart';

/// Resposta padrão para módulos ainda não implementados.
abstract final class RotaModuloUtil {
  static Response emImplementacao() {
    return RespostaJsonUtil.erro(
      mensagem: 'Endpoint em implementação.',
      statusCode: HttpStatus.notImplemented,
    );
  }

  static Response metodoNaoPermitido() {
    return RespostaJsonUtil.erro(
      mensagem: 'Método não permitido.',
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
}
