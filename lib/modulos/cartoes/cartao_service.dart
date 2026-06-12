import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/compartilhado/ordem_util.dart';
import 'package:kanban_api/core/dtos/cartao_dto.dart';
import 'package:kanban_api/modulos/cartoes/cartao_schema.dart';
import 'package:supabase/supabase.dart';

class CartaoService {
  CartaoService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<Cartao>> listarPorQuadro({
    required String usuarioId,
    required String quadroId,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoQuadro(quadroId);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final cartoes = await _supabase
        .schema('public')
        .from('cartoes')
        .select('''
          id,
          cliente_id,
          quadro_id,
          coluna_id,
          responsavel_id,
          titulo,
          observacao,
          ordem,
          valor_proposta,
          origem,
          criado_em,
          atualizado_em,
          clientes ( empresa ),
          colunas_quadros!inner ( ordem )
        ''')
        .eq('quadro_id', quadroId);

    final lista = (cartoes as List).map((item) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final cliente = mapa['clientes'];
      if (cliente is Map) {
        mapa['cliente_empresa'] = cliente['empresa'];
      }
      mapa.remove('clientes');

      final coluna = mapa['colunas_quadros'];
      if (coluna is Map) {
        mapa['_coluna_ordem'] = coluna['ordem'];
      }
      mapa.remove('colunas_quadros');

      if (mapa['origem'] != null) {
        mapa['origem'] = mapa['origem'].toString();
      }

      return mapa;
    }).toList();

    lista.sort((a, b) {
      final ordemColunaA = a['_coluna_ordem'] as int? ?? 0;
      final ordemColunaB = b['_coluna_ordem'] as int? ?? 0;
      if (ordemColunaA != ordemColunaB) {
        return ordemColunaA.compareTo(ordemColunaB);
      }
      return (a['ordem'] as int).compareTo(b['ordem'] as int);
    });

    if (lista.isEmpty) return [];

    final cartaoIds = lista.map((item) => item['id'] as String).toList();
    final agora = DateTime.now().toUtc().toIso8601String();

    final agendamentos = await _supabase
        .schema('public')
        .from('agendamentos')
        .select('cartao_id, titulo, data_hora_inicio')
        .eq('organizacao_id', organizacaoId)
        .eq('status', 'pendente')
        .gte('data_hora_inicio', agora)
        .inFilter('cartao_id', cartaoIds)
        .order('data_hora_inicio');

    final proximoPorCartao = <String, Map<String, dynamic>>{};
    for (final item in agendamentos as List) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final cartaoId = mapa['cartao_id'] as String?;
      if (cartaoId == null || proximoPorCartao.containsKey(cartaoId)) {
        continue;
      }
      proximoPorCartao[cartaoId] = mapa;
    }

    for (final cartao in lista) {
      cartao.remove('_coluna_ordem');
      final proximo = proximoPorCartao[cartao['id'] as String];
      if (proximo != null) {
        cartao['proximo_agendamento_titulo'] = proximo['titulo'];
        cartao['proximo_agendamento_data_hora_inicio'] =
            proximo['data_hora_inicio'];
      }
    }

    return lista.map(Cartao.fromMap).toList();
  }

  Future<Cartao> cadastrar({
    required String usuarioId,
    required CadastrarCartaoEntrada entrada,
  }) async {
    final organizacaoId =
        await _autorizacao.organizacaoIdDoQuadro(entrada.quadroId);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _validarCartao(
      quadroId: entrada.quadroId,
      colunaId: entrada.colunaId,
      clienteId: entrada.clienteId,
      organizacaoId: organizacaoId,
      responsavelId: entrada.responsavelId,
    );

    final ordem = await OrdemUtil.proximaOrdem(
      supabase: _supabase,
      tabela: 'cartoes',
      colunaFiltro: 'coluna_id',
      valorFiltro: entrada.colunaId,
    );

    final cartao = await _supabase
        .schema('public')
        .from('cartoes')
        .insert({
          'quadro_id': entrada.quadroId,
          'coluna_id': entrada.colunaId,
          'titulo': entrada.titulo,
          'observacao': entrada.observacao,
          'cliente_id': entrada.clienteId,
          'responsavel_id': entrada.responsavelId,
          'valor_proposta': entrada.valorProposta,
          'ordem': ordem,
        })
        .select()
        .single();

    return Cartao.fromMap(Map<String, dynamic>.from(cartao));
  }

  Future<Cartao> atualizar({
    required String usuarioId,
    required String id,
    required AtualizarCartaoEntrada entrada,
  }) async {
    final contexto = await _autorizacao.contextoDoCartao(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: contexto.organizacaoId,
    );

    await _validarCartao(
      quadroId: contexto.quadroId,
      colunaId: entrada.colunaId,
      clienteId: entrada.clienteId,
      organizacaoId: contexto.organizacaoId,
      responsavelId: entrada.responsavelId,
    );

    final atual = await _supabase
        .schema('public')
        .from('cartoes')
        .select('coluna_id, ordem')
        .eq('id', id)
        .single();

    final colunaAtual = atual['coluna_id'] as String;
    final ordem = colunaAtual == entrada.colunaId
        ? atual['ordem'] as int
        : await OrdemUtil.proximaOrdem(
            supabase: _supabase,
            tabela: 'cartoes',
            colunaFiltro: 'coluna_id',
            valorFiltro: entrada.colunaId,
          );

    final cartao = await _supabase
        .schema('public')
        .from('cartoes')
        .update({
          'coluna_id': entrada.colunaId,
          'titulo': entrada.titulo,
          'observacao': entrada.observacao,
          'cliente_id': entrada.clienteId,
          'responsavel_id': entrada.responsavelId,
          'valor_proposta': entrada.valorProposta,
          'ordem': ordem,
        })
        .eq('id', id)
        .select()
        .single();

    return Cartao.fromMap(Map<String, dynamic>.from(cartao));
  }

  Future<void> excluir({
    required String usuarioId,
    required String id,
  }) async {
    final contexto = await _autorizacao.contextoDoCartao(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: contexto.organizacaoId,
    );

    await _supabase.schema('public').from('cartoes').delete().eq('id', id);
  }

  Future<void> _validarCartao({
    required String quadroId,
    required String colunaId,
    required String clienteId,
    required String organizacaoId,
    String? responsavelId,
  }) async {
    final coluna = await _supabase
        .schema('public')
        .from('colunas_quadros')
        .select('id')
        .eq('id', colunaId)
        .eq('quadro_id', quadroId)
        .maybeSingle();

    if (coluna == null) {
      throw const ValidacaoException('Coluna não encontrada neste quadro.');
    }

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

    if (responsavelId != null &&
        !await _autorizacao.ehMembro(
          usuarioId: responsavelId,
          organizacaoId: organizacaoId,
        )) {
      throw const ValidacaoException(
        'Responsável não pertence à organização.',
      );
    }
  }
}
