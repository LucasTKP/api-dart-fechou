import 'package:dart_frog/dart_frog.dart';

/// Helpers para respostas HTTP padronizadas.
abstract final class RespostaJsonUtil {
  static Response sucesso({
    required Map<String, dynamic> dados,
    int statusCode = 200,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {'sucesso': true, 'dados': dados},
    );
  }

  static Response sucessoLista({
    required List<Map<String, dynamic>> dados,
    int statusCode = 200,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {'sucesso': true, 'dados': dados},
    );
  }

  static Response erro({
    required String mensagem,
    int statusCode = 400,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {'sucesso': false, 'erro': mensagem},
    );
  }
}
