/// Eventos enviados pelo WPPConnect no webhook.
enum EventoWppconnect {
  onmessage('onmessage'),
  onselfmessage('onselfmessage'),
  qrcode('qrcode'),
  statusFind('status-find'),
  closesession('closesession'),
  logoutsession('logoutsession'),
  desconhecido('');

  const EventoWppconnect(this.valor);

  final String valor;

  static EventoWppconnect fromValor(String? valor) {
    if (valor == null || valor.isEmpty) return desconhecido;

    return EventoWppconnect.values.firstWhere(
      (evento) => evento.valor == valor,
      orElse: () => desconhecido,
    );
  }

  bool get deveProcessarCaptacao => this == onmessage;
}
