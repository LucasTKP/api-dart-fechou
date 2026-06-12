import 'package:kanban_api/utils/data_util.dart';

class Agendamento {
  final String id;
  final String organizacaoId;
  final String criadoPor;
  final String? responsavelId;
  final String? clienteId;
  final String? cartaoId;
  final String titulo;
  final String? descricao;
  final String tipo;
  final String status;
  final DateTime dataHoraInicio;
  final DateTime? dataHoraFim;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Agendamento({
    required this.id,
    required this.organizacaoId,
    required this.criadoPor,
    required this.responsavelId,
    required this.clienteId,
    required this.cartaoId,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.status,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory Agendamento.fromMap(Map<String, dynamic> map) {
    return Agendamento(
      id: map['id'] as String,
      organizacaoId: map['organizacao_id'] as String,
      criadoPor: map['criado_por'] as String,
      responsavelId: map['responsavel_id'] as String?,
      clienteId: map['cliente_id'] as String?,
      cartaoId: map['cartao_id'] as String?,
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String?,
      tipo: map['tipo'].toString(),
      status: map['status'].toString(),
      dataHoraInicio: DataUtil.parse(map['data_hora_inicio'])!,
      dataHoraFim: DataUtil.parse(map['data_hora_fim']),
      criadoEm: DataUtil.parse(map['criado_em'])!,
      atualizadoEm: DataUtil.parse(map['atualizado_em'])!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizacao_id': organizacaoId,
      'criado_por': criadoPor,
      'responsavel_id': responsavelId,
      'cliente_id': clienteId,
      'cartao_id': cartaoId,
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo,
      'status': status,
      'data_hora_inicio': dataHoraInicio.toIso8601String(),
      'data_hora_fim': dataHoraFim?.toIso8601String(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }
}
