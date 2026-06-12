import 'package:kanban_api/utils/data_util.dart';

class MembroOrganizacao {
  final String id;
  final String usuarioId;
  final String papel;
  final String? nome;
  final String? email;
  final DateTime? entradoEm;

  const MembroOrganizacao({
    required this.id,
    required this.usuarioId,
    required this.papel,
    required this.nome,
    required this.email,
    required this.entradoEm,
  });

  factory MembroOrganizacao.fromMap(Map<String, dynamic> map) {
    return MembroOrganizacao(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      papel: map['papel'] as String,
      nome: map['nome'] as String?,
      email: map['email'] as String?,
      entradoEm: DataUtil.parse(map['entrado_em']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'papel': papel,
      'nome': nome,
      'email': email,
      'entrado_em': entradoEm?.toIso8601String(),
    };
  }
}
