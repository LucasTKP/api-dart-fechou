import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/core/dtos/membro_organizacao_dto.dart';
import 'package:kanban_api/core/dtos/organizacao_dto.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_schema.dart';
import 'package:supabase/supabase.dart';

class OrganizacaoService {
  OrganizacaoService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<Organizacao>> listar({required String usuarioId}) async {
    _autorizacao.assertAutenticado(usuarioId);

    final resposta = await _supabase
        .schema('public')
        .from('membros_organizacao')
        .select('organizacoes(*)')
        .eq('usuario_id', usuarioId);

    final organizacoes = <Organizacao>[];
    for (final item in resposta as List) {
      final org = item['organizacoes'];
      if (org is Map) {
        organizacoes.add(Organizacao.fromMap(Map<String, dynamic>.from(org)));
      }
    }

    organizacoes.sort((a, b) => a.nome.compareTo(b.nome));

    return organizacoes;
  }

  Future<Organizacao> cadastrar({
    required String usuarioId,
    required CadastrarOrganizacaoEntrada entrada,
  }) async {
    _autorizacao.assertAutenticado(usuarioId);

    final organizacao = await _supabase
        .schema('public')
        .from('organizacoes')
        .insert({
          'nome': entrada.nome,
          'criado_por': usuarioId,
          'ativa': false,
        })
        .select()
        .single();

    await _supabase.schema('public').from('membros_organizacao').insert({
      'organizacao_id': organizacao['id'],
      'usuario_id': usuarioId,
      'papel': 'proprietario',
    });

    return Organizacao.fromMap(Map<String, dynamic>.from(organizacao));
  }

  Future<Organizacao> buscarPorId({
    required String usuarioId,
    required String id,
  }) async {
    await _autorizacao.assertMembro(usuarioId: usuarioId, organizacaoId: id);

    final organizacao = await _supabase
        .schema('public')
        .from('organizacoes')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (organizacao == null) {
      throw const RecursoNaoEncontradoException('Organização não encontrada.');
    }

    return Organizacao.fromMap(Map<String, dynamic>.from(organizacao));
  }

  Future<Organizacao> atualizar({
    required String usuarioId,
    required String id,
    required AtualizarOrganizacaoEntrada entrada,
  }) async {
    await _autorizacao.assertAdmin(usuarioId: usuarioId, organizacaoId: id);

    final organizacao = await _supabase
        .schema('public')
        .from('organizacoes')
        .update({'nome': entrada.nome})
        .eq('id', id)
        .select()
        .maybeSingle();

    if (organizacao == null) {
      throw const RecursoNaoEncontradoException('Organização não encontrada.');
    }

    return Organizacao.fromMap(Map<String, dynamic>.from(organizacao));
  }

  Future<List<MembroOrganizacao>> listarMembros({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('membros_organizacao')
        .select('id, usuario_id, papel, entrado_em, usuarios(nome, email)')
        .eq('organizacao_id', organizacaoId);

    final membros = (resposta as List).map((item) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final usuario = mapa['usuarios'];
      if (usuario is Map) {
        mapa['nome'] = usuario['nome'];
        mapa['email'] = usuario['email'];
      }
      mapa.remove('usuarios');
      return MembroOrganizacao.fromMap(mapa);
    }).toList();

    const ordemPapeis = {'proprietario': 0, 'admin': 1, 'membro': 2};
    membros.sort((a, b) {
      final papelA = ordemPapeis[a.papel] ?? 99;
      final papelB = ordemPapeis[b.papel] ?? 99;
      if (papelA != papelB) return papelA.compareTo(papelB);
      return (a.nome ?? '').compareTo(b.nome ?? '');
    });

    return membros;
  }
}
