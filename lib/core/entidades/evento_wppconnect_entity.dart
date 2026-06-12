import 'package:equatable/equatable.dart';
import 'package:kanban_api/core/enums/evento_wppconnect_enum.dart';
import 'package:kanban_api/core/enums/tipo_mensagem_wppconnect_enum.dart';
import 'package:kanban_api/utils/telefone_whatsapp_util.dart';

/// Payload recebido do webhook do WPPConnect.
class EventoWppconnectEntity extends Equatable {
  const EventoWppconnectEntity({
    required this.evento,
    required this.sessao,
    required this.tipoMensagem,
    required this.de,
    required this.corpo,
    required this.nomeContato,
    required this.enviadaPorMim,
    required this.telefone,
  });

  final EventoWppconnect evento;
  final String sessao;
  final TipoMensagemWppconnect tipoMensagem;
  final String de;
  final String corpo;
  final String nomeContato;
  final bool enviadaPorMim;
  final String telefone;

  bool get deveProcessar =>
      evento.deveProcessarCaptacao &&
      !enviadaPorMim &&
      !tipoMensagem.deveIgnorar &&
      corpo.trim().isNotEmpty;

  factory EventoWppconnectEntity.fromMap(Map<String, dynamic> map) {
    final corpo = map['body']?.toString() ?? map['content']?.toString() ?? '';

    return EventoWppconnectEntity(
      evento: EventoWppconnect.fromValor(map['event']?.toString()),
      sessao: map['session']?.toString() ?? '',
      tipoMensagem: TipoMensagemWppconnect.fromValor(map['type']?.toString()),
      de: map['from']?.toString() ?? '',
      corpo: corpo,
      nomeContato: _extrairNomeContato(map),
      enviadaPorMim: map['fromMe'] == true,
      telefone: TelefoneWhatsappUtil.extrair(map),
    );
  }

  static String _extrairNomeContato(Map<String, dynamic> map) {
    final notifyName = map['notifyName']?.toString() ?? '';
    if (notifyName.isNotEmpty) return notifyName;

    final sender = map['sender'];
    if (sender is Map) {
      final pushname = Map<String, dynamic>.from(sender)['pushname']?.toString();
      if (pushname != null && pushname.isNotEmpty) return pushname;
    }

    return '';
  }

  @override
  List<Object?> get props => [
    evento,
    sessao,
    tipoMensagem,
    de,
    corpo,
    nomeContato,
    enviadaPorMim,
    telefone,
  ];
}
