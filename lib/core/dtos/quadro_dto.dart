import 'package:kanban_api/utils/data_util.dart';

class Quadro {
  final String id;
  final String organizacaoId;
  final String criadoPor;
  final String nome;
  final String? descricao;
  final String cor;
  final int ordem;
  final DateTime criadoEm;

  const Quadro({
    required this.id,
    required this.organizacaoId,
    required this.criadoPor,
    required this.nome,
    required this.descricao,
    required this.cor,
    required this.ordem,
    required this.criadoEm,
  });

  factory Quadro.fromMap(Map<String, dynamic> map) {
    return Quadro(
      id: map['id'] as String,
      organizacaoId: map['organizacao_id'] as String,
      criadoPor: map['criado_por'] as String,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      cor: map['cor'].toString(),
      ordem: map['ordem'] as int,
      criadoEm: DataUtil.parse(map['criado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizacao_id': organizacaoId,
      'criado_por': criadoPor,
      'nome': nome,
      'descricao': descricao,
      'cor': cor,
      'ordem': ordem,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
