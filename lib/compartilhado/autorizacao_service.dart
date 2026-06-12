import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:supabase/supabase.dart';

/// Regras de acesso por organização (equivalente às asserts do schema SQL).
class AutorizacaoService {
  AutorizacaoService(this._supabase);

  final SupabaseClient _supabase;

  void assertAutenticado(String usuarioId) {
    if (usuarioId.isEmpty) {
      throw const NaoAutenticadoException();
    }
  }

  Future<bool> ehMembro({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    final membro = await _supabase
        .schema('public')
        .from('membros_organizacao')
        .select('id')
        .eq('usuario_id', usuarioId)
        .eq('organizacao_id', organizacaoId)
        .maybeSingle();

    return membro != null;
  }

  Future<void> assertMembro({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    assertAutenticado(usuarioId);

    if (organizacaoId.isEmpty) {
      throw const ValidacaoException('Organização é obrigatória.');
    }

    final organizacao = await _supabase
        .schema('public')
        .from('organizacoes')
        .select('ativa')
        .eq('id', organizacaoId)
        .maybeSingle();

    if (organizacao == null) {
      throw const RecursoNaoEncontradoException('Organização não encontrada.');
    }

    if (organizacao['ativa'] != true) {
      throw const AcessoNegadoException('Organização inativa.');
    }

    if (!await ehMembro(usuarioId: usuarioId, organizacaoId: organizacaoId)) {
      throw const AcessoNegadoException('Usuário não pertence à organização.');
    }
  }

  Future<void> assertAdmin({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    await assertMembro(usuarioId: usuarioId, organizacaoId: organizacaoId);

    final membro = await _supabase
        .schema('public')
        .from('membros_organizacao')
        .select('papel')
        .eq('usuario_id', usuarioId)
        .eq('organizacao_id', organizacaoId)
        .single();

    final papel = membro['papel'] as String?;
    if (papel != 'proprietario' && papel != 'admin') {
      throw const AcessoNegadoException(
        'Permissão insuficiente na organização.',
      );
    }
  }

  Future<String> organizacaoIdDoCliente(String clienteId) async {
    return _buscarOrganizacaoId(
      tabela: 'clientes',
      id: clienteId,
      naoEncontrado: 'Cliente não encontrado.',
    );
  }

  Future<String> organizacaoIdDoQuadro(String quadroId) async {
    return _buscarOrganizacaoId(
      tabela: 'quadros',
      id: quadroId,
      naoEncontrado: 'Quadro não encontrado.',
    );
  }

  Future<({String quadroId, String organizacaoId})> contextoDoCartao(
    String cartaoId,
  ) async {
    final cartao = await _supabase
        .schema('public')
        .from('cartoes')
        .select('quadro_id, quadros(organizacao_id)')
        .eq('id', cartaoId)
        .maybeSingle();

    if (cartao == null) {
      throw const RecursoNaoEncontradoException('Cartão não encontrado.');
    }

    final quadros = cartao['quadros'];
    if (quadros is! Map) {
      throw const RecursoNaoEncontradoException('Cartão não encontrado.');
    }

    return (
      quadroId: cartao['quadro_id'] as String,
      organizacaoId: quadros['organizacao_id'] as String,
    );
  }

  Future<({String quadroId, String organizacaoId})> contextoDaColuna(
    String colunaId,
  ) async {
    final coluna = await _supabase
        .schema('public')
        .from('colunas_quadros')
        .select('quadro_id, quadros(organizacao_id)')
        .eq('id', colunaId)
        .maybeSingle();

    if (coluna == null) {
      throw const RecursoNaoEncontradoException('Coluna não encontrada.');
    }

    final quadros = coluna['quadros'];
    if (quadros is! Map) {
      throw const RecursoNaoEncontradoException('Coluna não encontrada.');
    }

    return (
      quadroId: coluna['quadro_id'] as String,
      organizacaoId: quadros['organizacao_id'] as String,
    );
  }

  Future<String> organizacaoIdDoAgendamento(String agendamentoId) async {
    return _buscarOrganizacaoId(
      tabela: 'agendamentos',
      id: agendamentoId,
      naoEncontrado: 'Agendamento não encontrado.',
    );
  }

  Future<String> organizacaoIdDaRegra(String regraId) async {
    return _buscarOrganizacaoId(
      tabela: 'regras_captacao_automatica',
      id: regraId,
      naoEncontrado: 'Regra de captação não encontrada.',
    );
  }

  Future<String> _buscarOrganizacaoId({
    required String tabela,
    required String id,
    required String naoEncontrado,
  }) async {
    final registro = await _supabase
        .schema('public')
        .from(tabela)
        .select('organizacao_id')
        .eq('id', id)
        .maybeSingle();

    final organizacaoId = registro?['organizacao_id'] as String?;
    if (organizacaoId == null) {
      throw RecursoNaoEncontradoException(naoEncontrado);
    }

    return organizacaoId;
  }
}
