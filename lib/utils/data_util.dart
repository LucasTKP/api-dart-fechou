abstract final class DataUtil {
  static DateTime? parse(Object? valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor.toString());
  }
}
