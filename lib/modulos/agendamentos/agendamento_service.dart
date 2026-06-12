import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/core/dtos/agendamento_dto.dart';
import 'package:kanban_api/modulos/agendamentos/agendamento_schema.dart';
import 'package:supabase/supabase.dart';

class AgendamentoService {
  AgendamentoService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<Agendamento>> listar({
    required String usuarioId,
    required ListarAgendamentosEntrada entrada,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: entrada.organizacaoId,
    );

    var query = _supabase
        .schema('public')
        .from('agendamentos')
        .select()
        .eq('organizacao_id', entrada.organizacaoId);

    if (entrada.dataInicio != null) {
      query = query.gte(
        'data_hora_inicio',
        entrada.dataInicio!.toUtc().toIso8601String(),
      );
    }

    if (entrada.dataFim != null) {
      query = query.lte(
        'data_hora_inicio',
        entrada.dataFim!.toUtc().toIso8601String(),
      );
    }

    if (entrada.status != null) {
      query = query.eq('status', entrada.status!);
    }

    if (entrada.clienteId != null) {
      query = query.eq('cliente_id', entrada.clienteId!);
    }

    if (entrada.cartaoId != null) {
      query = query.eq('cartao_id', entrada.cartaoId!);
    }

    final resposta = await query.order('data_hora_inicio');
    return _mapearLista(resposta);
  }

  Future<List<Agendamento>> listarPorCartao({
    required String usuarioId,
    required String cartaoId,
  }) async {
    final contexto = await _autorizacao.contextoDoCartao(cartaoId);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: contexto.organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('agendamentos')
        .select()
        .eq('cartao_id', cartaoId)
        .eq('organizacao_id', contexto.organizacaoId)
        .order('data_hora_inicio');

    return _mapearLista(resposta);
  }

  Future<Agendamento> cadastrar({
    required String usuarioId,
    required CadastrarAgendamentoEntrada entrada,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: entrada.organizacaoId,
    );

    final responsavelFinal = entrada.responsavelId ?? usuarioId;
    if (!await _autorizacao.ehMembro(
      usuarioId: responsavelFinal,
      organizacaoId: entrada.organizacaoId,
    )) {
      throw const ValidacaoException(
        'Responsável não pertence à organização.',
      );
    }

    await _validarClienteECartao(
      organizacaoId: entrada.organizacaoId,
      clienteId: entrada.clienteId,
      cartaoId: entrada.cartaoId,
    );

    final agendamento = await _supabase
        .schema('public')
        .from('agendamentos')
        .insert({
          'organizacao_id': entrada.organizacaoId,
          'criado_por': usuarioId,
          'responsavel_id': responsavelFinal,
          'cliente_id': entrada.clienteId,
          'cartao_id': entrada.cartaoId,
          'titulo': entrada.titulo,
          'descricao': entrada.descricao,
          'tipo': entrada.tipo,
          'data_hora_inicio': entrada.dataHoraInicio.toUtc().toIso8601String(),
          'data_hora_fim': entrada.dataHoraFim?.toUtc().toIso8601String(),
        })
        .select()
        .single();

    return Agendamento.fromMap(Map<String, dynamic>.from(agendamento));
  }

  Future<Agendamento> atualizar({
    required String usuarioId,
    required String id,
    required AtualizarAgendamentoEntrada entrada,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoAgendamento(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final atual = await _supabase
        .schema('public')
        .from('agendamentos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (atual == null) {
      throw const RecursoNaoEncontradoException('Agendamento não encontrado.');
    }

    final responsavelFinal =
        entrada.responsavelId ?? atual['responsavel_id'] as String? ?? usuarioId;

    if (!await _autorizacao.ehMembro(
      usuarioId: responsavelFinal,
      organizacaoId: organizacaoId,
    )) {
      throw const ValidacaoException(
        'Responsável não pertence à organização.',
      );
    }

    final clienteFinal = entrada.clienteId ?? atual['cliente_id'] as String?;
    final cartaoFinal = entrada.cartaoId ?? atual['cartao_id'] as String?;

    await _validarClienteECartao(
      organizacaoId: organizacaoId,
      clienteId: clienteFinal,
      cartaoId: cartaoFinal,
    );

    final agendamento = await _supabase
        .schema('public')
        .from('agendamentos')
        .update({
          'titulo': entrada.titulo,
          'descricao': entrada.descricao,
          'tipo': entrada.tipo,
          'data_hora_inicio': entrada.dataHoraInicio.toUtc().toIso8601String(),
          'data_hora_fim': entrada.dataHoraFim?.toUtc().toIso8601String(),
          if (entrada.status != null) 'status': entrada.status,
          'cliente_id': clienteFinal,
          'cartao_id': cartaoFinal,
          'responsavel_id': responsavelFinal,
        })
        .eq('id', id)
        .select()
        .single();

    return Agendamento.fromMap(Map<String, dynamic>.from(agendamento));
  }

  Future<Agendamento> cancelar({
    required String usuarioId,
    required String id,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoAgendamento(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final atual = await _supabase
        .schema('public')
        .from('agendamentos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (atual == null) {
      throw const RecursoNaoEncontradoException('Agendamento não encontrado.');
    }

    if (atual['status'] == 'cancelado') {
      return Agendamento.fromMap(Map<String, dynamic>.from(atual));
    }

    final agendamento = await _supabase
        .schema('public')
        .from('agendamentos')
        .update({'status': 'cancelado'})
        .eq('id', id)
        .select()
        .single();

    return Agendamento.fromMap(Map<String, dynamic>.from(agendamento));
  }

  Future<void> excluir({
    required String usuarioId,
    required String id,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoAgendamento(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _supabase.schema('public').from('agendamentos').delete().eq('id', id);
  }

  Future<void> _validarClienteECartao({
    required String organizacaoId,
    String? clienteId,
    String? cartaoId,
  }) async {
    if (clienteId != null) {
      final cliente = await _supabase
          .schema('public')
          .from('clientes')
          .select('id')
          .eq('id', clienteId)
          .eq('organizacao_id', organizacaoId)
          .maybeSingle();

      if (cliente == null) {
        throw const ValidacaoException('Cliente não encontrado.');
      }
    }

    if (cartaoId != null) {
      final cartao = await _supabase
          .schema('public')
          .from('cartoes')
          .select('cliente_id, quadros!inner(organizacao_id)')
          .eq('id', cartaoId)
          .maybeSingle();

      if (cartao == null) {
        throw const ValidacaoException('Cartão não encontrado.');
      }

      final quadros = cartao['quadros'];
      if (quadros is! Map || quadros['organizacao_id'] != organizacaoId) {
        throw const ValidacaoException('Cartão não encontrado.');
      }

      if (clienteId != null) {
        final clienteCartao = cartao['cliente_id'] as String?;
        if (clienteCartao != null && clienteCartao != clienteId) {
          throw const ValidacaoException(
            'Cliente informado não corresponde ao cartão.',
          );
        }
      }
    }
  }

  List<Agendamento> _mapearLista(dynamic resposta) {
    return (resposta as List)
        .map(
          (item) =>
              Agendamento.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
