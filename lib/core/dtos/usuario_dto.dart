import 'package:kanban_api/utils/data_util.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final DateTime criadoEm;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.criadoEm,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      criadoEm: DataUtil.parse(map['criado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
