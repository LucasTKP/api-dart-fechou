import 'package:http/http.dart' as http;
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/modulos/whatsapp/contato_whatsapp_resolver.dart';
import 'package:kanban_api/modulos/whatsapp/wppconnect_cliente.dart';
import 'package:test/test.dart';

class _WppConnectFake extends WppConnectCliente {
  _WppConnectFake(this._telefonesPorJid) : super(http.Client());

  final Map<String, String?> _telefonesPorJid;
  final chamadas = <String>[];

  @override
  Future<String?> resolverTelefonePorJid(String sessao, String jidContato) {
    chamadas.add(jidContato);
    return Future.value(_telefonesPorJid[jidContato]);
  }
}

void main() {
  group('ContatoWhatsappResolver', () {
    test('resolve @c.us via rota pn-lid', () async {
      final cliente = _WppConnectFake({
        '5516999999999@c.us': '5516999999999',
      });
      final resolver = ContatoWhatsappResolver(cliente);

      final telefone = await resolver.resolverTelefone(
        sessao: 'sessao_teste',
        payload: {'from': '5516999999999@c.us'},
      );

      expect(telefone, '5516999999999');
      expect(cliente.chamadas, ['5516999999999@c.us']);
    });

    test('resolve @lid via rota pn-lid', () async {
      final cliente = _WppConnectFake({
        '120808890482833@lid': '5516991614062',
      });
      final resolver = ContatoWhatsappResolver(cliente);

      final telefone = await resolver.resolverTelefone(
        sessao: 'sessao_teste',
        payload: {
          'from': '120808890482833@lid',
          'sender': {
            'formattedName': 'Lucas',
          },
        },
      );

      expect(telefone, '5516991614062');
      expect(cliente.chamadas, ['120808890482833@lid']);
    });

    test('falha quando a rota pn-lid não retorna telefone', () async {
      final resolver = ContatoWhatsappResolver(
        _WppConnectFake({
          '120808890482833@lid': null,
        }),
      );

      expect(
        () => resolver.resolverTelefone(
          sessao: 'sessao_teste',
          payload: {'from': '120808890482833@lid'},
        ),
        throwsA(isA<ValidacaoException>()),
      );
    });
  });
}
