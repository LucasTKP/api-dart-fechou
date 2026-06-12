import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/config/ambiente.dart';

/// Resposta binária (ex.: imagem do QR Code) do WPPConnect.
class RespostaBinariaWpp {
  const RespostaBinariaWpp({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Cliente HTTP de baixo nível para o WPPConnect Server.
///
/// É o ÚNICO ponto que conhece a `secretKey`. Gera e mantém em cache o token
/// de cada sessão, repetindo a requisição quando o token expira (401).
class WppConnectCliente {
  WppConnectCliente(this._http);

  final http.Client _http;
  final Map<String, String> _tokensPorSessao = {};

  String get _urlBase => Ambiente.wppconnectBaseUrl;
  String get _secretKey => Ambiente.wppconnectSecretKey;

  Uri _uri(String caminho) => Uri.parse('$_urlBase$caminho');

  Future<String> _garantirToken(String sessao) async {
    final emCache = _tokensPorSessao[sessao];
    if (emCache != null) return emCache;

    final resposta = await _http.post(
      _uri('/api/$sessao/$_secretKey/generate-token'),
    );

    if (resposta.statusCode >= 400) {
      throw _erroDoCorpo(
        resposta,
        padrao: 'Não foi possível gerar o token da sessão.',
      );
    }

    final corpo = _decodificarMapa(resposta.body);
    final token = corpo['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ValidacaoException(
        'WPPConnect não retornou o token da sessão.',
      );
    }

    _tokensPorSessao[sessao] = token;
    return token;
  }

  void invalidarToken(String sessao) => _tokensPorSessao.remove(sessao);

  Map<String, String> _headersAuth(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Executa [acao] com token válido, renovando-o uma vez em caso de 401.
  Future<http.Response> _comToken(
    String sessao,
    Future<http.Response> Function(String token) acao,
  ) async {
    final token = await _garantirToken(sessao);
    var resposta = await acao(token);

    if (resposta.statusCode == 401) {
      invalidarToken(sessao);
      final novoToken = await _garantirToken(sessao);
      resposta = await acao(novoToken);
    }

    return resposta;
  }

  Future<Map<String, dynamic>> statusSessao(String sessao) async {
    final resposta = await _comToken(
      sessao,
      (token) => _http.get(
        _uri('/api/$sessao/status-session'),
        headers: _headersAuth(token),
      ),
    );

    if (resposta.statusCode >= 400) {
      throw _erroDoCorpo(
        resposta,
        padrao: 'Não foi possível consultar o status da sessão.',
      );
    }

    return _decodificarMapa(resposta.body);
  }

  Future<Map<String, dynamic>> iniciarSessao(String sessao) async {
    final resposta = await _comToken(
      sessao,
      (token) => _http.post(
        _uri('/api/$sessao/start-session'),
        headers: _headersAuth(token),
        body: jsonEncode({
          'webhook': Ambiente.whatsappWebhookUrl,
          'waitQrCode': true,
        }),
      ),
    );

    if (resposta.statusCode >= 400) {
      throw _erroDoCorpo(
        resposta,
        padrao: 'Não foi possível iniciar a sessão.',
      );
    }

    return _decodificarMapa(resposta.body);
  }

  Future<RespostaBinariaWpp> qrCode(String sessao) async {
    final resposta = await _comToken(
      sessao,
      (token) => _http.get(
        _uri('/api/$sessao/qrcode-session'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (resposta.statusCode >= 400) {
      throw _erroDoCorpo(
        resposta,
        padrao: 'QR Code indisponível no momento.',
      );
    }

    return RespostaBinariaWpp(
      bytes: resposta.bodyBytes,
      contentType: resposta.headers['content-type'] ?? 'image/png',
    );
  }

  Future<void> encerrarSessao(String sessao) async {
    final resposta = await _comToken(
      sessao,
      (token) => _http.post(
        _uri('/api/$sessao/close-session'),
        headers: _headersAuth(token),
      ),
    );

    invalidarToken(sessao);

    if (resposta.statusCode >= 400) {
      throw _erroDoCorpo(
        resposta,
        padrao: 'Não foi possível encerrar a sessão.',
      );
    }
  }

  /// Resolve telefone via rota `contact/pn-lid` (`@lid` ou `@c.us`).
  Future<String?> resolverTelefonePorJid(String sessao, String jidContato) async {
    final jidCodificado = Uri.encodeComponent(jidContato);
    final resposta = await _comToken(
      sessao,
      (token) => _http.get(
        _uri('/api/$sessao/contact/pn-lid/$jidCodificado'),
        headers: _headersAuth(token),
      ),
    );

    if (resposta.statusCode >= 400) {
      return null;
    }

    final corpo = _decodificarMapa(resposta.body);
    final phoneNumber = corpo['phoneNumber'];
    if (phoneNumber is! Map) return null;

    final phoneMap = Map<String, dynamic>.from(phoneNumber);
    final serializado = phoneMap['_serialized']?.toString() ?? '';
    if (serializado.endsWith('@c.us')) {
      return serializado.split('@').first;
    }

    final id = phoneMap['id']?.toString() ?? '';
    return id.isNotEmpty ? id : null;
  }

  Future<void> limparDadosSessao(String sessao) async {
    final resposta = await _http.post(
      _uri('/api/$sessao/$_secretKey/clear-session-data'),
    );

    invalidarToken(sessao);

    if (resposta.statusCode >= 400) {
      throw _erroDoCorpo(
        resposta,
        padrao: 'Não foi possível limpar os dados da sessão.',
      );
    }
  }

  Map<String, dynamic> _decodificarMapa(String corpo) {
    if (corpo.isEmpty) return <String, dynamic>{};

    final decodificado = jsonDecode(corpo);
    if (decodificado is Map<String, dynamic>) return decodificado;
    if (decodificado is Map) return Map<String, dynamic>.from(decodificado);

    return <String, dynamic>{};
  }

  ValidacaoException _erroDoCorpo(
    http.Response resposta, {
    required String padrao,
  }) {
    try {
      final corpo = _decodificarMapa(resposta.body);
      final mensagem = corpo['message'] ?? corpo['error'] ?? corpo['response'];
      if (mensagem is String && mensagem.isNotEmpty) {
        return ValidacaoException(mensagem);
      }
    } catch (_) {
      // Corpo não é JSON; usa a mensagem padrão.
    }

    return ValidacaoException(padrao);
  }
}
