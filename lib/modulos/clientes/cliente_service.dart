import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/excecoes_api.dart';
import 'package:kanban_api/core/dtos/cliente_dto.dart';
import 'package:kanban_api/modulos/clientes/cliente_schema.dart';
import 'package:supabase/supabase.dart';

class ClienteService {
  ClienteService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<List<Cliente>> listar({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('clientes')
        .select()
        .eq('organizacao_id', organizacaoId)
        .order('nome');

    return (resposta as List)
        .map((item) => Cliente.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Cliente> cadastrar({
    required String usuarioId,
    required CadastrarClienteEntrada entrada,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: entrada.organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('clientes')
        .insert({
          'organizacao_id': entrada.organizacaoId,
          'criado_por': usuarioId,
          'nome': entrada.nome,
          'email': entrada.email,
          'telefone': entrada.telefone,
          'empresa': entrada.empresa,
        })
        .select()
        .single();

    return Cliente.fromMap(Map<String, dynamic>.from(resposta));
  }

  Future<Cliente> atualizar({
    required String usuarioId,
    required String id,
    required AtualizarClienteEntrada entrada,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoCliente(id);

    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    final resposta = await _supabase
        .schema('public')
        .from('clientes')
        .update({
          'nome': entrada.nome,
          'email': entrada.email,
          'telefone': entrada.telefone,
          'empresa': entrada.empresa,
        })
        .eq('id', id)
        .eq('organizacao_id', organizacaoId)
        .select()
        .maybeSingle();

    if (resposta == null) {
      throw const RecursoNaoEncontradoException('Cliente não encontrado.');
    }

    return Cliente.fromMap(Map<String, dynamic>.from(resposta));
  }

  Future<void> excluir({
    required String usuarioId,
    required String id,
  }) async {
    final organizacaoId = await _autorizacao.organizacaoIdDoCliente(id);

    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _supabase
        .schema('public')
        .from('clientes')
        .delete()
        .eq('id', id)
        .eq('organizacao_id', organizacaoId);
  }
}
