import 'package:dart_frog/dart_frog.dart';

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
    Map<String, String> headers = const {},  // ← adicionado
  }) {
    return Response.json(
      statusCode: statusCode,
      headers: headers,                       // ← adicionado
      body: {'sucesso': false, 'erro': mensagem},
    );
  }
}