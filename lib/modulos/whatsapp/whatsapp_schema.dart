import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class SessaoWhatsappEntrada {
  final String organizacaoId;

  const SessaoWhatsappEntrada({required this.organizacaoId});
}

abstract final class WhatsappSchema {
  static final sessao = z.inferType<SessaoWhatsappEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
    }),
    fromMap: (json) =>
        SessaoWhatsappEntrada(organizacaoId: json['organizacao_id'] as String),
  );
}
