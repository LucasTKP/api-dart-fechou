import 'package:kanban_api/utils/data_util.dart';

class Organizacao {
  final String id;
  final String nome;
  final String criadoPor;
  final bool ativa;
  final DateTime criadoEm;

  const Organizacao({
    required this.id,
    required this.nome,
    required this.criadoPor,
    required this.ativa,
    required this.criadoEm,
  });

  factory Organizacao.fromMap(Map<String, dynamic> map) {
    return Organizacao(
      id: map['id'] as String,
      nome: map['nome'] as String,
      criadoPor: map['criado_por'] as String,
      ativa: map['ativa'] as bool? ?? false,
      criadoEm: DataUtil.parse(map['criado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'criado_por': criadoPor,
      'ativa': ativa,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
