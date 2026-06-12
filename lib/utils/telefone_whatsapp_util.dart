/// Extrai telefone legível a partir do payload do WPPConnect.
abstract final class TelefoneWhatsappUtil {
  static String extrair(Map<String, dynamic> map) {
    final de = map['from']?.toString() ?? '';

    if (_ehJidTelefone(de)) {
      return de.split('@').first;
    }

    final sender = map['sender'];
    if (sender is Map) {
      final senderMap = Map<String, dynamic>.from(sender);

      final nomeFormatado = senderMap['formattedName']?.toString() ?? '';
      if (nomeFormatado.isNotEmpty) {
        return nomeFormatado;
      }

      final idSender = senderMap['id']?.toString() ?? '';
      if (_ehJidTelefone(idSender)) {
        return idSender.split('@').first;
      }
    }

    final chatId = map['chatId']?.toString() ?? '';
    if (_ehJidTelefone(chatId)) {
      return chatId.split('@').first;
    }

    return de.split('@').first;
  }

  static bool _ehJidTelefone(String jid) {
    return jid.endsWith('@c.us') || jid.endsWith('@s.whatsapp.net');
  }
}
