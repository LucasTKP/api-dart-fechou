import 'package:zard/zard.dart';

abstract final class CamposSchema {
  static const coresKanban = [
    'azul',
    'verde',
    'vermelho',
    'amarelo',
    'roxo',
    'laranja',
    'rosa',
    'cinza',
  ];

  static Schema<String> textoObrigatorio(String mensagem) =>
      z.string(message: mensagem).trim().refine(
            (valor) => valor.trim().isNotEmpty,
            message: mensagem,
          );

  static Schema<String> cor(String padrao) =>
      z.$enum(coresKanban, message: 'Cor inválida.').$default(padrao);
}
