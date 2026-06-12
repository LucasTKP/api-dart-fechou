import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

const _origens = ['whatsapp', 'instagram', 'trafego_pago', 'indicacao'];

class ListarCaptacaoEntrada {
  final String organizacaoId;

  const ListarCaptacaoEntrada({required this.organizacaoId});
}

class CadastrarRegraEntrada {
  final String organizacaoId;
  final String nome;
  final String palavraChave;
  final String quadroId;
  final String colunaId;
  final String origem;
  final bool ativo;

  const CadastrarRegraEntrada({
    required this.organizacaoId,
    required this.nome,
    required this.palavraChave,
    required this.quadroId,
    required this.colunaId,
    required this.origem,
    required this.ativo,
  });
}

class AtualizarRegraEntrada {
  final String nome;
  final String palavraChave;
  final String quadroId;
  final String colunaId;
  final String origem;
  final bool ativo;

  const AtualizarRegraEntrada({
    required this.nome,
    required this.palavraChave,
    required this.quadroId,
    required this.colunaId,
    required this.origem,
    required this.ativo,
  });
}

abstract final class CaptacaoAutomaticaSchema {
  static final listar = z.inferType<ListarCaptacaoEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarCaptacaoEntrada(organizacaoId: json['organizacao_id'] as String),
  );

  static final cadastrar = z.inferType<CadastrarRegraEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
      'nome': CamposSchema.textoObrigatorio('Nome da regra é obrigatório.'),
      'palavra_chave':
          CamposSchema.textoObrigatorio('Palavra-chave é obrigatória.'),
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
      'coluna_id': CamposSchema.textoObrigatorio('coluna_id é obrigatório.'),
      'origem': z.$enum(_origens, message: 'Origem inválida.'),
      'ativo': z.bool().$default(true),
    }),
    fromMap: (json) => CadastrarRegraEntrada(
      organizacaoId: json['organizacao_id'] as String,
      nome: json['nome'] as String,
      palavraChave: json['palavra_chave'] as String,
      quadroId: json['quadro_id'] as String,
      colunaId: json['coluna_id'] as String,
      origem: json['origem'] as String,
      ativo: json['ativo'] as bool,
    ),
  );

  static final atualizar = z.inferType<AtualizarRegraEntrada>(
    mapSchema: z.map({
      'nome': CamposSchema.textoObrigatorio('Nome da regra é obrigatório.'),
      'palavra_chave':
          CamposSchema.textoObrigatorio('Palavra-chave é obrigatória.'),
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
      'coluna_id': CamposSchema.textoObrigatorio('coluna_id é obrigatório.'),
      'origem': z.$enum(_origens, message: 'Origem inválida.'),
      'ativo': z.bool(),
    }),
    fromMap: (json) => AtualizarRegraEntrada(
      nome: json['nome'] as String,
      palavraChave: json['palavra_chave'] as String,
      quadroId: json['quadro_id'] as String,
      colunaId: json['coluna_id'] as String,
      origem: json['origem'] as String,
      ativo: json['ativo'] as bool,
    ),
  );
}
