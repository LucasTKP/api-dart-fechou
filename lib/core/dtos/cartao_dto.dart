import 'package:kanban_api/utils/data_util.dart';

class Cartao {
  final String id;
  final String? clienteId;
  final String quadroId;
  final String colunaId;
  final String? responsavelId;
  final String titulo;
  final String? observacao;
  final int ordem;
  final int? valorProposta;
  final String? origem;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? clienteEmpresa;
  final String? proximoAgendamentoTitulo;
  final String? proximoAgendamentoDataHoraInicio;

  const Cartao({
    required this.id,
    required this.clienteId,
    required this.quadroId,
    required this.colunaId,
    required this.responsavelId,
    required this.titulo,
    required this.observacao,
    required this.ordem,
    required this.valorProposta,
    required this.origem,
    required this.criadoEm,
    required this.atualizadoEm,
    this.clienteEmpresa,
    this.proximoAgendamentoTitulo,
    this.proximoAgendamentoDataHoraInicio,
  });

  factory Cartao.fromMap(Map<String, dynamic> map) {
    return Cartao(
      id: map['id'] as String,
      clienteId: map['cliente_id'] as String?,
      quadroId: map['quadro_id'] as String,
      colunaId: map['coluna_id'] as String,
      responsavelId: map['responsavel_id'] as String?,
      titulo: map['titulo'] as String,
      observacao: map['observacao'] as String?,
      ordem: map['ordem'] as int,
      valorProposta: map['valor_proposta'] as int?,
      origem: map['origem']?.toString(),
      criadoEm: DataUtil.parse(map['criado_em'])!,
      atualizadoEm: DataUtil.parse(map['atualizado_em'])!,
      clienteEmpresa: map['cliente_empresa'] as String?,
      proximoAgendamentoTitulo: map['proximo_agendamento_titulo'] as String?,
      proximoAgendamentoDataHoraInicio:
          map['proximo_agendamento_data_hora_inicio']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'quadro_id': quadroId,
      'coluna_id': colunaId,
      'responsavel_id': responsavelId,
      'titulo': titulo,
      'observacao': observacao,
      'ordem': ordem,
      'valor_proposta': valorProposta,
      'origem': origem,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      if (clienteEmpresa != null) 'cliente_empresa': clienteEmpresa,
      if (proximoAgendamentoTitulo != null)
        'proximo_agendamento_titulo': proximoAgendamentoTitulo,
      if (proximoAgendamentoDataHoraInicio != null)
        'proximo_agendamento_data_hora_inicio':
            proximoAgendamentoDataHoraInicio,
    };
  }
}
