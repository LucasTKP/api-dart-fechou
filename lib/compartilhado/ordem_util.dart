import 'package:supabase/supabase.dart';

abstract final class OrdemUtil {
  static Future<int> proximaOrdem({
    required SupabaseClient supabase,
    required String tabela,
    required String colunaFiltro,
    required String valorFiltro,
  }) async {
    final ultimo = await supabase
        .schema('public')
        .from(tabela)
        .select('ordem')
        .eq(colunaFiltro, valorFiltro)
        .order('ordem', ascending: false)
        .limit(1)
        .maybeSingle();

    final ordemAtual = ultimo?['ordem'] as int?;
    return (ordemAtual ?? -1) + 1;
  }
}
