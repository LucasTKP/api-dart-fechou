import 'package:equatable/equatable.dart';
import 'package:kanban_api/core/entidades/resultado_captacao_automatica_entity.dart';
import 'package:kanban_api/core/entidades/regra_captacao_resumida_entity.dart';

enum StatusProcessamentoWebhook {
  ignorado,
  semRegra,
  captacaoExecutada,
}

/// Resposta interna do processamento do webhook WhatsApp.
class ResultadoWebhookWhatsappEntity extends Equatable {
  const ResultadoWebhookWhatsappEntity({
    required this.status,
    this.motivo,
    this.regra,
    this.captacao,
  });

  final StatusProcessamentoWebhook status;
  final String? motivo;
  final RegraCaptacaoResumidaEntity? regra;
  final ResultadoCaptacaoAutomaticaEntity? captacao;

  Map<String, dynamic> toMap() => {
    'status': status.name,
    if (motivo != null) 'motivo': motivo,
    if (regra != null) 'regra': regra!.toMap(),
    if (captacao != null) 'captacao': captacao!.toMap(),
  };

  @override
  List<Object?> get props => [status, motivo, regra, captacao];
}
