import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/modulos/whatsapp/wppconnect_cliente.dart';
import 'package:kanban_api/utils/telefone_whatsapp_util.dart';

/// Resolve o telefone do remetente a partir do payload do webhook.
///
/// Fluxo único: extrai o JID do contato e consulta sempre a rota
/// `contact/pn-lid` do WPPConnect.
class ContatoWhatsappResolver {
  ContatoWhatsappResolver(this._wppConnect);

  final WppConnectCliente _wppConnect;

  Future<String> resolverTelefone({
    required String sessao,
    required Map<String, dynamic> payload,
  }) async {
    final jidContato = TelefoneWhatsappUtil.extrairJidContato(payload);

    if (!TelefoneWhatsappUtil.ehJidContato(jidContato)) {
      throw const ValidacaoException('Telefone inválido.');
    }

    final resolvido = await _wppConnect.resolverTelefonePorJid(
      sessao,
      jidContato,
    );

    if (resolvido != null && resolvido.isNotEmpty) {
      return resolvido;
    }

    throw const ValidacaoException('Telefone inválido.');
  }
}
