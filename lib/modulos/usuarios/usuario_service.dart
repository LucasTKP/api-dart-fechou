import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/core/dtos/usuario_dto.dart';
import 'package:kanban_api/modulos/usuarios/usuario_schema.dart';
import 'package:supabase/supabase.dart';

class UsuarioService {
  UsuarioService(this._supabase, this._autorizacao);

  final SupabaseClient _supabase;
  final AutorizacaoService _autorizacao;

  Future<Usuario?> buscarPorId({required String usuarioId}) async {
    final resposta = await _supabase
        .schema('public')
        .from('usuarios')
        .select()
        .eq('id', usuarioId)
        .maybeSingle();

    if (resposta == null) return null;
    return Usuario.fromMap(Map<String, dynamic>.from(resposta));
  }

  Future<Usuario> cadastrar({
    required String usuarioId,
    required CadastrarUsuarioEntrada cadastrarUsuarioEntrada,
  }) async {
    _autorizacao.assertAutenticado(usuarioId);

    await _supabase.schema('public').from('usuarios').upsert({
      'id': usuarioId,
      'nome': cadastrarUsuarioEntrada.nome,
      'email': cadastrarUsuarioEntrada.email,
    });

    final possuiOrganizacao = await _supabase
        .schema('public')
        .from('membros_organizacao')
        .select('id')
        .eq('usuario_id', usuarioId)
        .limit(1)
        .maybeSingle();

    if (possuiOrganizacao == null) {
      final organizacao = await _supabase
          .schema('public')
          .from('organizacoes')
          .insert({
            'nome': 'Minha organização',
            'criado_por': usuarioId,
          })
          .select('id')
          .single();

      await _supabase.schema('public').from('membros_organizacao').insert({
        'organizacao_id': organizacao['id'],
        'usuario_id': usuarioId,
        'papel': 'proprietario',
      });
    }

    final usuario = await _supabase
        .schema('public')
        .from('usuarios')
        .select()
        .eq('id', usuarioId)
        .single();

    return Usuario.fromMap(usuario);
  }
}
