/// Tipos de mensagem do WhatsApp ignorados no fluxo de captação.
enum TipoMensagemWppconnect {
  chat('chat'),
  e2eNotification('e2e_notification'),
  notificationTemplate('notification_template'),
  protocol('protocol'),
  gp2('gp2'),
  callLog('call_log'),
  ciphertext('ciphertext'),
  revoked('revoked'),
  desconhecido('');

  const TipoMensagemWppconnect(this.valor);

  final String valor;

  static TipoMensagemWppconnect fromValor(String? valor) {
    if (valor == null || valor.isEmpty) return desconhecido;

    return TipoMensagemWppconnect.values.firstWhere(
      (tipo) => tipo.valor == valor,
      orElse: () => desconhecido,
    );
  }

  bool get deveIgnorar => switch (this) {
    TipoMensagemWppconnect.chat => false,
    TipoMensagemWppconnect.desconhecido => false,
    _ => true,
  };
}
