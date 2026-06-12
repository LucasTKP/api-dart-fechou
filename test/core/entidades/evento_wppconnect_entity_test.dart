import 'package:kanban_api/core/entidades/evento_wppconnect_entity.dart';
import 'package:kanban_api/core/enums/evento_wppconnect_enum.dart';
import 'package:kanban_api/core/enums/tipo_mensagem_wppconnect_enum.dart';
import 'package:test/test.dart';

void main() {
  group('EventoWppconnectEntity', () {
    test('parseia payload real com @lid e session da organização', () {
      final evento = EventoWppconnectEntity.fromMap({
        'event': 'onmessage',
        'session': '7eaa284f_ad2e_4f41_96fe_e3d67177cb7c',
        'body': 'Oi3',
        'content': 'Oi3',
        'type': 'chat',
        'notifyName': 'Lucas',
        'from': '120808890482833@lid',
        'chatId': '120808890482833@lid',
        'fromMe': false,
        'sender': {
          'id': '120808890482833@lid',
          'pushname': 'Lucas',
          'formattedName': '+55 16 99161-4062',
        },
      });

      expect(evento.evento, EventoWppconnect.onmessage);
      expect(evento.sessao, '7eaa284f_ad2e_4f41_96fe_e3d67177cb7c');
      expect(evento.tipoMensagem, TipoMensagemWppconnect.chat);
      expect(evento.corpo, 'Oi3');
      expect(evento.nomeContato, 'Lucas');
      expect(evento.enviadaPorMim, isFalse);
      expect(evento.deveProcessar, isTrue);
      expect(evento.telefone, '+55 16 99161-4062');
    });

    test('usa from @c.us quando disponível', () {
      final evento = EventoWppconnectEntity.fromMap({
        'event': 'onmessage',
        'session': 'abc_def',
        'body': 'Olá',
        'type': 'chat',
        'from': '5516999999999@c.us',
        'fromMe': false,
      });

      expect(evento.telefone, '5516999999999');
      expect(evento.deveProcessar, isTrue);
    });
  });
}
