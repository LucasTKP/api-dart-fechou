import 'package:kanban_api/utils/telefone_whatsapp_util.dart';
import 'package:test/test.dart';

void main() {
  group('TelefoneWhatsappUtil', () {
    test('extrai JID @lid ignorando formattedName', () {
      final payload = {
        'from': '120808890482833@lid',
        'chatId': '120808890482833@lid',
        'sender': {
          'id': '120808890482833@lid',
          'formattedName': 'Lucas',
        },
      };

      expect(
        TelefoneWhatsappUtil.extrairJidContato(payload),
        '120808890482833@lid',
      );
      expect(
        TelefoneWhatsappUtil.ehJidContato('120808890482833@lid'),
        isTrue,
      );
    });

    test('extrai JID @c.us', () {
      expect(
        TelefoneWhatsappUtil.extrairJidContato({
          'from': '5516999999999@c.us',
        }),
        '5516999999999@c.us',
      );
      expect(
        TelefoneWhatsappUtil.ehJidContato('5516999999999@c.us'),
        isTrue,
      );
    });

    test('prioriza from sobre chatId e sender', () {
      expect(
        TelefoneWhatsappUtil.extrairJidContato({
          'from': '111@c.us',
          'chatId': '222@c.us',
          'sender': {'id': '333@c.us'},
        }),
        '111@c.us',
      );
    });
  });
}
