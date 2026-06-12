/// Converte entre nome de sessão WPPConnect e ID da organização.
abstract final class SessaoWhatsappUtil {
  static String organizacaoIdDeSessao(String sessao) {
    return sessao.replaceAll('_', '-');
  }

  static String sessaoDeOrganizacaoId(String organizacaoId) {
    return organizacaoId.replaceAll('-', '_');
  }
}
