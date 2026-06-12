import 'package:kanban_api/core/entidades/evento_wppconnect_entity.dart';
import 'package:kanban_api/core/entidades/resultado_webhook_whatsapp_entity.dart';
import 'package:kanban_api/modulos/captacao_automatica/captacao_automatica_service.dart';
import 'package:kanban_api/modulos/whatsapp/contato_whatsapp_resolver.dart';
import 'package:kanban_api/utils/sessao_whatsapp_util.dart';

class WebhookWhatsappService {
  WebhookWhatsappService(this._captacaoAutomatica, this._contatoResolver);

  final CaptacaoAutomaticaService _captacaoAutomatica;
  final ContatoWhatsappResolver _contatoResolver;

  Future<ResultadoWebhookWhatsappEntity> processar(
    Map<String, dynamic> payload,
  ) async {
    final evento = EventoWppconnectEntity.fromMap(payload);

    if (!evento.deveProcessar) {
      return const ResultadoWebhookWhatsappEntity(
        status: StatusProcessamentoWebhook.ignorado,
        motivo: 'Evento ou mensagem fora do fluxo de captação.',
      );
    }

    if (evento.sessao.isEmpty) {
      return const ResultadoWebhookWhatsappEntity(
        status: StatusProcessamentoWebhook.ignorado,
        motivo: 'Sessão não informada.',
      );
    }

    final organizacaoId = SessaoWhatsappUtil.organizacaoIdDeSessao(
      evento.sessao,
    );

    final regra = await _captacaoAutomatica.buscarRegraPorMensagem(
      organizacaoId: organizacaoId,
      mensagem: evento.corpo,
    );

    if (regra == null) {
      return const ResultadoWebhookWhatsappEntity(
        status: StatusProcessamentoWebhook.semRegra,
        motivo: 'Nenhuma regra ativa corresponde à mensagem.',
      );
    }

    final telefone = await _contatoResolver.resolverTelefone(
      sessao: evento.sessao,
      payload: payload,
    );

    final captacao = await _captacaoAutomatica.executar(
      regraId: regra.id,
      nomeContato: evento.nomeContato,
      telefone: telefone,
    );

    return ResultadoWebhookWhatsappEntity(
      status: StatusProcessamentoWebhook.captacaoExecutada,
      regra: regra,
      captacao: captacao,
    );
  }
}
