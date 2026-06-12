import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

const _tipos = ['reuniao', 'ligacao', 'visita'];
const _status = ['pendente', 'concluido', 'cancelado'];
const _mensagemDatas = 'Data e hora de fim devem ser posteriores ao início.';

bool _datasValidas(Map<String, dynamic> dados) {
  final inicio = dados['data_hora_inicio'];
  final fim = dados['data_hora_fim'];
  if (inicio is DateTime && fim is DateTime) {
    return !fim.isBefore(inicio);
  }
  return true;
}

class ListarAgendamentosEntrada {
  final String organizacaoId;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? status;
  final String? clienteId;
  final String? cartaoId;

  const ListarAgendamentosEntrada({
    required this.organizacaoId,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
    required this.clienteId,
    required this.cartaoId,
  });
}

class ListarPorCartaoEntrada {
  final String cartaoId;

  const ListarPorCartaoEntrada({required this.cartaoId});
}

class CadastrarAgendamentoEntrada {
  final String organizacaoId;
  final String titulo;
  final String tipo;
  final DateTime dataHoraInicio;
  final String? clienteId;
  final String? cartaoId;
  final String? descricao;
  final DateTime? dataHoraFim;
  final String? responsavelId;

  const CadastrarAgendamentoEntrada({
    required this.organizacaoId,
    required this.titulo,
    required this.tipo,
    required this.dataHoraInicio,
    required this.clienteId,
    required this.cartaoId,
    required this.descricao,
    required this.dataHoraFim,
    required this.responsavelId,
  });
}

class AtualizarAgendamentoEntrada {
  final String titulo;
  final String tipo;
  final DateTime dataHoraInicio;
  final String? descricao;
  final DateTime? dataHoraFim;
  final String? status;
  final String? clienteId;
  final String? cartaoId;
  final String? responsavelId;

  const AtualizarAgendamentoEntrada({
    required this.titulo,
    required this.tipo,
    required this.dataHoraInicio,
    required this.descricao,
    required this.dataHoraFim,
    required this.status,
    required this.clienteId,
    required this.cartaoId,
    required this.responsavelId,
  });
}

class CancelarAgendamentoEntrada {
  final String id;

  const CancelarAgendamentoEntrada({required this.id});
}

abstract final class AgendamentoSchema {
  static final listar = z.inferType<ListarAgendamentosEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
      'data_inicio': z.coerce.date().nullish(),
      'data_fim': z.coerce.date().nullish(),
      'status': z.$enum(_status, message: 'Status inválido.').nullish(),
      'cliente_id': z.string().nullish(),
      'cartao_id': z.string().nullish(),
    }),
    fromMap: (json) => ListarAgendamentosEntrada(
      organizacaoId: json['organizacao_id'] as String,
      dataInicio: json['data_inicio'] as DateTime?,
      dataFim: json['data_fim'] as DateTime?,
      status: json['status'] as String?,
      clienteId: json['cliente_id'] as String?,
      cartaoId: json['cartao_id'] as String?,
    ),
  );

  static final listarPorCartao = z.inferType<ListarPorCartaoEntrada>(
    mapSchema: z.map({
      'cartao_id': CamposSchema.textoObrigatorio('cartao_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarPorCartaoEntrada(cartaoId: json['cartao_id'] as String),
  );

  static final cadastrar = z.inferType<CadastrarAgendamentoEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
      'titulo':
          CamposSchema.textoObrigatorio('Título do agendamento é obrigatório.'),
      'tipo': z.$enum(_tipos, message: 'Tipo de agendamento inválido.'),
      'data_hora_inicio': z.coerce.date(),
      'cliente_id': z.string().nullish(),
      'cartao_id': z.string().nullish(),
      'descricao': z.string().nullish(),
      'data_hora_fim': z.coerce.date().nullish(),
      'responsavel_id': z.string().nullish(),
    }).refine(_datasValidas, message: _mensagemDatas),
    fromMap: (json) => CadastrarAgendamentoEntrada(
      organizacaoId: json['organizacao_id'] as String,
      titulo: json['titulo'] as String,
      tipo: json['tipo'] as String,
      dataHoraInicio: json['data_hora_inicio'] as DateTime,
      clienteId: json['cliente_id'] as String?,
      cartaoId: json['cartao_id'] as String?,
      descricao: json['descricao'] as String?,
      dataHoraFim: json['data_hora_fim'] as DateTime?,
      responsavelId: json['responsavel_id'] as String?,
    ),
  );

  static final atualizar = z.inferType<AtualizarAgendamentoEntrada>(
    mapSchema: z.map({
      'titulo':
          CamposSchema.textoObrigatorio('Título do agendamento é obrigatório.'),
      'tipo': z.$enum(_tipos, message: 'Tipo de agendamento inválido.'),
      'data_hora_inicio': z.coerce.date(),
      'descricao': z.string().nullish(),
      'data_hora_fim': z.coerce.date().nullish(),
      'status': z.$enum(_status, message: 'Status inválido.').nullish(),
      'cliente_id': z.string().nullish(),
      'cartao_id': z.string().nullish(),
      'responsavel_id': z.string().nullish(),
    }).refine(_datasValidas, message: _mensagemDatas),
    fromMap: (json) => AtualizarAgendamentoEntrada(
      titulo: json['titulo'] as String,
      tipo: json['tipo'] as String,
      dataHoraInicio: json['data_hora_inicio'] as DateTime,
      descricao: json['descricao'] as String?,
      dataHoraFim: json['data_hora_fim'] as DateTime?,
      status: json['status'] as String?,
      clienteId: json['cliente_id'] as String?,
      cartaoId: json['cartao_id'] as String?,
      responsavelId: json['responsavel_id'] as String?,
    ),
  );

  static final cancelar = z.inferType<CancelarAgendamentoEntrada>(
    mapSchema: z.map({
      'id': CamposSchema.textoObrigatorio('id é obrigatório.'),
    }),
    fromMap: (json) => CancelarAgendamentoEntrada(id: json['id'] as String),
  );
}
