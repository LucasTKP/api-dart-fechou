/// Extrai o identificador do contato a partir do payload do WPPConnect.
abstract final class TelefoneWhatsappUtil {
  /// JID do remetente (`@c.us`, `@s.whatsapp.net` ou `@lid`).
  static String extrairJidContato(Map<String, dynamic> map) {
    for (final campo in ['from', 'chatId']) {
      final jid = map[campo]?.toString() ?? '';
      if (ehJidContato(jid)) return jid;
    }

    final sender = map['sender'];
    if (sender is Map) {
      final id = Map<String, dynamic>.from(sender)['id']?.toString() ?? '';
      if (ehJidContato(id)) return id;
    }

    return map['from']?.toString() ?? '';
  }

  static bool ehJidContato(String jid) {
    return jid.endsWith('@c.us') ||
        jid.endsWith('@s.whatsapp.net') ||
        jid.endsWith('@lid');
  }
}
