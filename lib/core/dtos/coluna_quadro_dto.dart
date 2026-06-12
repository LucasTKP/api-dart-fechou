import 'package:kanban_api/utils/data_util.dart';

class ColunaQuadro {
  final String id;
  final String quadroId;
  final String nome;
  final String cor;
  final int ordem;
  final DateTime criadoEm;

  const ColunaQuadro({
    required this.id,
    required this.quadroId,
    required this.nome,
    required this.cor,
    required this.ordem,
    required this.criadoEm,
  });

  factory ColunaQuadro.fromMap(Map<String, dynamic> map) {
    return ColunaQuadro(
      id: map['id'] as String,
      quadroId: map['quadro_id'] as String,
      nome: map['nome'] as String,
      cor: map['cor'].toString(),
      ordem: map['ordem'] as int,
      criadoEm: DataUtil.parse(map['criado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quadro_id': quadroId,
      'nome': nome,
      'cor': cor,
      'ordem': ordem,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
