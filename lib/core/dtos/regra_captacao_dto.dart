import 'package:kanban_api/utils/data_util.dart';

class RegraCaptacao {
  final String id;
  final String organizacaoId;
  final String criadoPor;
  final String nome;
  final String palavraChave;
  final String? palavraChaveNormalizada;
  final String quadroId;
  final String colunaId;
  final String origem;
  final bool ativo;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const RegraCaptacao({
    required this.id,
    required this.organizacaoId,
    required this.criadoPor,
    required this.nome,
    required this.palavraChave,
    required this.palavraChaveNormalizada,
    required this.quadroId,
    required this.colunaId,
    required this.origem,
    required this.ativo,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory RegraCaptacao.fromMap(Map<String, dynamic> map) {
    return RegraCaptacao(
      id: map['id'] as String,
      organizacaoId: map['organizacao_id'] as String,
      criadoPor: map['criado_por'] as String,
      nome: map['nome'] as String,
      palavraChave: map['palavra_chave'] as String,
      palavraChaveNormalizada: map['palavra_chave_normalizada'] as String?,
      quadroId: map['quadro_id'] as String,
      colunaId: map['coluna_id'] as String,
      origem: map['origem'].toString(),
      ativo: map['ativo'] as bool,
      criadoEm: DataUtil.parse(map['criado_em'])!,
      atualizadoEm: DataUtil.parse(map['atualizado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizacao_id': organizacaoId,
      'criado_por': criadoPor,
      'nome': nome,
      'palavra_chave': palavraChave,
      'palavra_chave_normalizada': palavraChaveNormalizada,
      'quadro_id': quadroId,
      'coluna_id': colunaId,
      'origem': origem,
      'ativo': ativo,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }
}
