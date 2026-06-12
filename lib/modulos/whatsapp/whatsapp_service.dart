import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/modulos/whatsapp/wppconnect_cliente.dart';
import 'package:kanban_api/utils/sessao_whatsapp_util.dart';

/// Orquestra as operações de WhatsApp por organização.
///
/// Garante que o usuário é membro da organização antes de falar com o
/// WPPConnect e traduz o `organizacao_id` no nome de sessão esperado.
class WhatsappService {
  WhatsappService(this._autorizacao, this._cliente);

  final AutorizacaoService _autorizacao;
  final WppConnectCliente _cliente;

  Future<String> _sessaoAutorizada({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    await _autorizacao.assertMembro(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    return SessaoWhatsappUtil.sessaoDeOrganizacaoId(organizacaoId);
  }

  Future<Map<String, dynamic>> status({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    final sessao = await _sessaoAutorizada(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    return _cliente.statusSessao(sessao);
  }

  Future<Map<String, dynamic>> conectar({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    final sessao = await _sessaoAutorizada(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    return _cliente.iniciarSessao(sessao);
  }

  Future<RespostaBinariaWpp> qrCode({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    final sessao = await _sessaoAutorizada(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    return _cliente.qrCode(sessao);
  }

  Future<void> encerrar({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    final sessao = await _sessaoAutorizada(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _cliente.encerrarSessao(sessao);
  }

  Future<void> limparDados({
    required String usuarioId,
    required String organizacaoId,
  }) async {
    final sessao = await _sessaoAutorizada(
      usuarioId: usuarioId,
      organizacaoId: organizacaoId,
    );

    await _cliente.limparDadosSessao(sessao);
  }
}
