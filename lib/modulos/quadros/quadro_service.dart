import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/ordem_util.dart';
import 'package:kanban_api/core/dtos/quadro_dto.dart';
import 'package:kanban_api/modulos/quadros/quadro_schema.dart';
import 'package:supabase/supabase.dart';

class QuadroService {
  QuadroService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<Quadro>> listar({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('quadros')
        .select()
        .eq('organizacao_id', organizacaoId)
        .order('ordem');

    return (resposta as List)
        .map((item) => Quadro.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Quadro> cadastrar({
    required String usuarioId,
    required CadastrarQuadroEntrada entrada,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: entrada.organizacaoId,
    );

    final ordem = await OrdemUtil.proximaOrdem(
      supabase: _supabase,
      tabela: 'quadros',
      colunaFiltro: 'organizacao_id',
      valorFiltro: entrada.organizacaoId,
    );

    final quadro = await _supabase
        .schema('public')
        .from('quadros')
        .insert({
          'organizacao_id': entrada.organizacaoId,
          'criado_por': usuarioId,
          'nome': entrada.nome,
          'descricao': entrada.descricao,
          'cor': entrada.cor,
          'ordem': ordem,
        })
        .select()
        .single();

    return Quadro.fromMap(Map<String, dynamic>.from(quadro));
  }
}
