import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/compartilhado/ordem_util.dart';
import 'package:kanban_api/core/dtos/coluna_quadro_dto.dart';
import 'package:kanban_api/modulos/colunas_quadro/coluna_quadro_schema.dart';
import 'package:supabase/supabase.dart';

class ColunaQuadroService {
  ColunaQuadroService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<ColunaQuadro>> listar({
    required String usuarioId,
    required String quadroId,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoQuadro(quadroId);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('colunas_quadros')
        .select()
        .eq('quadro_id', quadroId)
        .order('ordem');

    return (resposta as List)
        .map(
          (item) => ColunaQuadro.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ColunaQuadro> cadastrar({
    required String usuarioId,
    required CadastrarColunaEntrada entrada,
  }) async {
    final organizacaoId =
        await _autorizacao.organizacaoIdDoQuadro(entrada.quadroId);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final ordem = await OrdemUtil.proximaOrdem(
      supabase: _supabase,
      tabela: 'colunas_quadros',
      colunaFiltro: 'quadro_id',
      valorFiltro: entrada.quadroId,
    );

    final coluna = await _supabase
        .schema('public')
        .from('colunas_quadros')
        .insert({
          'quadro_id': entrada.quadroId,
          'nome': entrada.nome,
          'cor': entrada.cor,
          'ordem': ordem,
        })
        .select()
        .single();

    return ColunaQuadro.fromMap(Map<String, dynamic>.from(coluna));
  }

  Future<ColunaQuadro> atualizar({
    required String usuarioId,
    required String id,
    required AtualizarColunaEntrada entrada,
  }) async {
    _autorizacao.assertAutenticado(usuarioId);

    final contexto = await _autorizacao.contextoDaColuna(id);
    final ehMembro = await _autorizacao.ehMembro(
      usuarioId: usuarioId,
      organizacaoId: contexto.organizacaoId,
    );

    if (!ehMembro) {
      throw const AcessoNegadoException('Usuário não pertence à organização.');
    }

    final coluna = await _supabase
        .schema('public')
        .from('colunas_quadros')
        .update({
          'nome': entrada.nome,
          'cor': entrada.cor,
        })
        .eq('id', id)
        .eq('quadro_id', contexto.quadroId)
        .select()
        .maybeSingle();

    if (coluna == null) {
      throw const RecursoNaoEncontradoException('Coluna não encontrada.');
    }

    return ColunaQuadro.fromMap(Map<String, dynamic>.from(coluna));
  }

  Future<void> reordenar({
    required String usuarioId,
    required ReordenarColunasEntrada entrada,
  }) async {
    final organizacaoId =
        await _autorizacao.organizacaoIdDoQuadro(entrada.quadroId);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final colunas = await _supabase
        .schema('public')
        .from('colunas_quadros')
        .select('id')
        .eq('quadro_id', entrada.quadroId);

    final idsExistentes =
        (colunas as List).map((item) => item['id'] as String).toSet();

    if (entrada.colunaIds.length != idsExistentes.length) {
      throw const ValidacaoException(
        'A lista de colunas não corresponde ao quadro.',
      );
    }

    if (!entrada.colunaIds.every(idsExistentes.contains)) {
      throw const ValidacaoException(
        'A lista de colunas não corresponde ao quadro.',
      );
    }

    for (var i = 0; i < entrada.colunaIds.length; i++) {
      await _supabase
          .schema('public')
          .from('colunas_quadros')
          .update({'ordem': i})
          .eq('id', entrada.colunaIds[i])
          .eq('quadro_id', entrada.quadroId);
    }
  }

  Future<void> excluir({
    required String usuarioId,
    required String id,
    String? colunaDestinoId,
  }) async {
    final contexto = await _autorizacao.contextoDaColuna(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: contexto.organizacaoId,
    );

    final cartoes = await _supabase
        .schema('public')
        .from('cartoes')
        .select('id, ordem, criado_em')
        .eq('coluna_id', id)
        .order('ordem')
        .order('criado_em');

    final listaCartoes = cartoes as List;

    if (listaCartoes.isNotEmpty) {
      if (colunaDestinoId == null) {
        throw const ValidacaoException(
          'Informe uma coluna de destino para transferir os cards.',
        );
      }

      if (colunaDestinoId == id) {
        throw const ValidacaoException(
          'A coluna de destino deve ser diferente da coluna excluída.',
        );
      }

      final destino = await _supabase
          .schema('public')
          .from('colunas_quadros')
          .select('id')
          .eq('id', colunaDestinoId)
          .eq('quadro_id', contexto.quadroId)
          .maybeSingle();

      if (destino == null) {
        throw const ValidacaoException(
          'Coluna de destino não encontrada neste quadro.',
        );
      }

      final ordemBase = await OrdemUtil.proximaOrdem(
        supabase: _supabase,
        tabela: 'cartoes',
        colunaFiltro: 'coluna_id',
        valorFiltro: colunaDestinoId,
      );

      for (var i = 0; i < listaCartoes.length; i++) {
        await _supabase
            .schema('public')
            .from('cartoes')
            .update({
              'coluna_id': colunaDestinoId,
              'ordem': ordemBase + i,
            })
            .eq('id', listaCartoes[i]['id'] as String);
      }
    }

    await _supabase
        .schema('public')
        .from('colunas_quadros')
        .delete()
        .eq('id', id)
        .eq('quadro_id', contexto.quadroId);
  }
}
