import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/compartilhado/normalizacao_util.dart';
import 'package:kanban_api/compartilhado/ordem_util.dart';
import 'package:kanban_api/core/dtos/regra_captacao_dto.dart';
import 'package:kanban_api/core/entidades/regra_captacao_resumida_entity.dart';
import 'package:kanban_api/core/entidades/resultado_captacao_automatica_entity.dart';
import 'package:kanban_api/modulos/captacao_automatica/captacao_automatica_schema.dart';
import 'package:supabase/supabase.dart';

class CaptacaoAutomaticaService {
  CaptacaoAutomaticaService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<RegraCaptacao>> listar({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('regras_captacao_automatica')
        .select()
        .eq('organizacao_id', organizacaoId)
        .order('criado_em', ascending: false);

    return (resposta as List)
        .map(
          (item) =>
              RegraCaptacao.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<RegraCaptacao> cadastrar({
    required String usuarioId,
    required CadastrarRegraEntrada entrada,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: entrada.organizacaoId,
    );

    await _validarQuadroColuna(
      organizacaoId: entrada.organizacaoId,
      quadroId: entrada.quadroId,
      colunaId: entrada.colunaId,
    );

    if (NormalizacaoUtil.normalizarTextoMensagem(entrada.palavraChave).isEmpty) {
      throw const ValidacaoException('Palavra-chave é obrigatória.');
    }

    final regra = await _supabase
        .schema('public')
        .from('regras_captacao_automatica')
        .insert({
          'organizacao_id': entrada.organizacaoId,
          'criado_por': usuarioId,
          'nome': entrada.nome,
          'palavra_chave': entrada.palavraChave,
          'quadro_id': entrada.quadroId,
          'coluna_id': entrada.colunaId,
          'origem': entrada.origem,
          'ativo': entrada.ativo,
        })
        .select()
        .single();

    return RegraCaptacao.fromMap(Map<String, dynamic>.from(regra));
  }

  Future<RegraCaptacao> atualizar({
    required String usuarioId,
    required String id,
    required AtualizarRegraEntrada entrada,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDaRegra(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _validarQuadroColuna(
      organizacaoId: organizacaoId,
      quadroId: entrada.quadroId,
      colunaId: entrada.colunaId,
    );

    if (NormalizacaoUtil.normalizarTextoMensagem(entrada.palavraChave).isEmpty) {
      throw const ValidacaoException('Palavra-chave é obrigatória.');
    }

    final regra = await _supabase
        .schema('public')
        .from('regras_captacao_automatica')
        .update({
          'nome': entrada.nome,
          'palavra_chave': entrada.palavraChave,
          'quadro_id': entrada.quadroId,
          'coluna_id': entrada.colunaId,
          'origem': entrada.origem,
          'ativo': entrada.ativo,
        })
        .eq('id', id)
        .select()
        .maybeSingle();

    if (regra == null) {
      throw const RecursoNaoEncontradoException(
        'Regra de captação não encontrada.',
      );
    }

    return RegraCaptacao.fromMap(Map<String, dynamic>.from(regra));
  }

  Future<void> excluir({
    required String usuarioId,
    required String id,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDaRegra(id);
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _supabase
        .schema('public')
        .from('regras_captacao_automatica')
        .delete()
        .eq('id', id);
  }

  Future<RegraCaptacaoResumidaEntity?> buscarRegraPorMensagem({
    required String organizacaoId,
    required String mensagem,
  }) async {
    final texto = NormalizacaoUtil.normalizarTextoMensagem(mensagem);
    if (texto.isEmpty) return null;

    final regras = await _supabase
        .schema('public')
        .from('regras_captacao_automatica')
        .select(
          'id, nome, palavra_chave, palavra_chave_normalizada, '
          'quadro_id, coluna_id, origem, criado_em',
        )
        .eq('organizacao_id', organizacaoId)
        .eq('ativo', true);

    Map<String, dynamic>? melhor;
    var maiorChave = -1;
    DateTime? maisAntiga;

    for (final item in regras as List) {
      final regra = Map<String, dynamic>.from(item as Map);
      final chave =
          regra['palavra_chave_normalizada'] as String? ?? '';
      if (chave.isEmpty || !texto.contains(chave)) continue;

      final tamanho = chave.length;
      final criadoEm = DateTime.parse(regra['criado_em'] as String);

      if (melhor == null ||
          tamanho > maiorChave ||
          (tamanho == maiorChave &&
              (maisAntiga == null || criadoEm.isBefore(maisAntiga)))) {
        melhor = regra;
        maiorChave = tamanho;
        maisAntiga = criadoEm;
      }
    }

    if (melhor == null) return null;

    return RegraCaptacaoResumidaEntity.fromMap({
      'id': melhor['id'],
      'nome': melhor['nome'],
      'palavra_chave': melhor['palavra_chave'],
      'quadro_id': melhor['quadro_id'],
      'coluna_id': melhor['coluna_id'],
      'origem': melhor['origem']?.toString(),
    });
  }

  Future<ResultadoCaptacaoAutomaticaEntity> executar({
    required String regraId,
    required String nomeContato,
    required String telefone,
  }) async {
    final regra = await _supabase
        .schema('public')
        .from('regras_captacao_automatica')
        .select('organizacao_id, quadro_id, coluna_id, origem')
        .eq('id', regraId)
        .eq('ativo', true)
        .maybeSingle();

    if (regra == null) {
      throw const ValidacaoException(
        'Regra de captação não encontrada ou inativa.',
      );
    }

    final organizacaoId = regra['organizacao_id'] as String;
    final quadroId = regra['quadro_id'] as String;
    final colunaId = regra['coluna_id'] as String;
    final origem = regra['origem']?.toString();

    final org = await _supabase
        .schema('public')
        .from('organizacoes')
        .select('ativa, criado_por')
        .eq('id', organizacaoId)
        .maybeSingle();

    if (org == null || org['ativa'] != true) {
      throw const ValidacaoException('Organização inativa.');
    }

    final telefoneNormalizado =
        NormalizacaoUtil.normalizarTelefoneBr(telefone);
    if (telefoneNormalizado.isEmpty ||
        (telefoneNormalizado.length != 10 &&
            telefoneNormalizado.length != 11)) {
      throw const ValidacaoException('Telefone inválido.');
    }

    var clienteCriado = false;
    var cartaoCriado = false;

    final clientes = await _supabase
        .schema('public')
        .from('clientes')
        .select('id, nome, telefone, criado_em')
        .eq('organizacao_id', organizacaoId)
        .order('criado_em');

    String? clienteId;
    var nomeCliente = '';

    for (final item in clientes as List) {
      final cliente = Map<String, dynamic>.from(item as Map);
      final tel = NormalizacaoUtil.normalizarTelefoneBr(
        cliente['telefone'] as String?,
      );
      if (tel == telefoneNormalizado) {
        clienteId = cliente['id'] as String;
        nomeCliente = cliente['nome'] as String;
        break;
      }
    }

    if (clienteId == null) {
      nomeCliente = nomeContato.trim().isEmpty
          ? 'Lead WhatsApp'
          : nomeContato.trim();

      final novoCliente = await _supabase
          .schema('public')
          .from('clientes')
          .insert({
            'organizacao_id': organizacaoId,
            'criado_por': org['criado_por'],
            'nome': nomeCliente,
            'telefone': telefoneNormalizado,
          })
          .select('id')
          .single();

      clienteId = novoCliente['id'] as String;
      clienteCriado = true;
    }

    final cartoesExistentes = await _supabase
        .schema('public')
        .from('cartoes')
        .select('id')
        .eq('coluna_id', colunaId)
        .eq('cliente_id', clienteId)
        .order('criado_em')
        .limit(1)
        .maybeSingle();

    String cartaoId;
    if (cartoesExistentes != null) {
      cartaoId = cartoesExistentes['id'] as String;
    } else {
      final ordem = await OrdemUtil.proximaOrdem(
        supabase: _supabase,
        tabela: 'cartoes',
        colunaFiltro: 'coluna_id',
        valorFiltro: colunaId,
      );

      final novoCartao = await _supabase
          .schema('public')
          .from('cartoes')
          .insert({
            'quadro_id': quadroId,
            'coluna_id': colunaId,
            'titulo': nomeCliente,
            'cliente_id': clienteId,
            'origem': origem,
            'ordem': ordem,
          })
          .select('id')
          .single();

      cartaoId = novoCartao['id'] as String;
      cartaoCriado = true;
    }

    return ResultadoCaptacaoAutomaticaEntity.fromMap({
      'regra_id': regraId,
      'cliente_id': clienteId,
      'cartao_id': cartaoId,
      'cliente_criado': clienteCriado,
      'cartao_criado': cartaoCriado,
    });
  }

  Future<void> _validarQuadroColuna({
    required String organizacaoId,
    required String quadroId,
    required String colunaId,
  }) async {
    final quadro = await _supabase
        .schema('public')
        .from('quadros')
        .select('organizacao_id')
        .eq('id', quadroId)
        .maybeSingle();

    if (quadro == null) {
      throw const ValidacaoException('Quadro não encontrado.');
    }

    if (quadro['organizacao_id'] != organizacaoId) {
      throw const ValidacaoException('Quadro não pertence à organização.');
    }

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
  }
}
