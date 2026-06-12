import 'package:kanban_api/utils/data_util.dart';

class Cliente {
  final String id;
  final String organizacaoId;
  final String criadoPor;
  final String nome;
  final String? email;
  final String? telefone;
  final String? empresa;
  final DateTime criadoEm;

  const Cliente({
    required this.id,
    required this.organizacaoId,
    required this.criadoPor,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.empresa,
    required this.criadoEm,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as String,
      organizacaoId: map['organizacao_id'] as String,
      criadoPor: map['criado_por'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String?,
      telefone: map['telefone'] as String?,
      empresa: map['empresa'] as String?,
      criadoEm: DataUtil.parse(map['criado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizacao_id': organizacaoId,
      'criado_por': criadoPor,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'empresa': empresa,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
