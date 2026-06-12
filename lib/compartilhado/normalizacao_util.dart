/// Equivalentes Dart das funções `private.normalizar_*` do schema SQL.
abstract final class NormalizacaoUtil {
  static String normalizarTextoMensagem(String? texto) {
    final valor = texto ?? '';
    final semEspacosExtras = valor.trim().replaceAll(RegExp(r'\s+'), ' ');
    return semEspacosExtras.toLowerCase();
  }

  static String normalizarTelefoneBr(String? telefone) {
    var digitos = (telefone ?? '').replaceAll(RegExp(r'\D'), '');
    if ((digitos.length == 12 || digitos.length == 13) && digitos.startsWith('55')) {
      digitos = digitos.substring(2);
    }
    return digitos;
  }
}
