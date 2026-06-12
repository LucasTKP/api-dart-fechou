import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:kanban_api/compartilhado/autorizacao_service.dart';
import 'package:kanban_api/compartilhado/validador_jwt_supabase.dart';
import 'package:kanban_api/config/ambiente.dart';
import 'package:kanban_api/modulos/agendamentos/agendamento_controller.dart';
import 'package:kanban_api/modulos/agendamentos/agendamento_service.dart';
import 'package:kanban_api/modulos/captacao_automatica/captacao_automatica_controller.dart';
import 'package:kanban_api/modulos/captacao_automatica/captacao_automatica_service.dart';
import 'package:kanban_api/modulos/cartoes/cartao_controller.dart';
import 'package:kanban_api/modulos/cartoes/cartao_service.dart';
import 'package:kanban_api/modulos/clientes/cliente_controller.dart';
import 'package:kanban_api/modulos/clientes/cliente_service.dart';
import 'package:kanban_api/modulos/colunas_quadro/coluna_quadro_controller.dart';
import 'package:kanban_api/modulos/colunas_quadro/coluna_quadro_service.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_controller.dart';
import 'package:kanban_api/modulos/organizacoes/organizacao_service.dart';
import 'package:kanban_api/modulos/quadros/quadro_controller.dart';
import 'package:kanban_api/modulos/quadros/quadro_service.dart';
import 'package:kanban_api/modulos/usuarios/usuario_controller.dart';
import 'package:kanban_api/modulos/usuarios/usuario_service.dart';
import 'package:kanban_api/modulos/webhook/webhook_whatsapp_controller.dart';
import 'package:kanban_api/modulos/webhook/webhook_whatsapp_service.dart';
import 'package:kanban_api/modulos/whatsapp/contato_whatsapp_resolver.dart';
import 'package:kanban_api/modulos/whatsapp/whatsapp_controller.dart';
import 'package:kanban_api/modulos/whatsapp/whatsapp_service.dart';
import 'package:kanban_api/modulos/whatsapp/wppconnect_cliente.dart';
import 'package:supabase/supabase.dart';

/// Service locator global da API.
final GetIt getIt = GetIt.instance;

/// Registra dependências singleton (Supabase, services e controllers).
///
/// Idempotente: chamadas repetidas (ex.: por requisição) são ignoradas.
/// O [ContextoUsuario] não é registrado aqui porque é específico de cada
/// requisição — continua sendo provido pelo `authMiddleware` via Dart Frog.
void configurarInjecaoDependencia() {
  if (getIt.isRegistered<SupabaseClient>()) return;

  getIt
    ..registerLazySingleton<SupabaseClient>(() => Ambiente.supabase)
    ..registerLazySingleton<ValidadorJwtSupabase>(
      () => ValidadorJwtSupabase(
        jwtSecret: Ambiente.supabaseJwtSecret,
        supabaseUrl: Ambiente.supabaseUrl,
      ),
    )
    ..registerLazySingleton<AutorizacaoService>(
      () => AutorizacaoService(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<ClienteService>(
      () => ClienteService(getIt<SupabaseClient>(), getIt<AutorizacaoService>()),
    )
    ..registerLazySingleton<ClienteController>(
      () => ClienteController(getIt<ClienteService>()),
    )
    ..registerLazySingleton<OrganizacaoService>(
      () => OrganizacaoService(
        getIt<SupabaseClient>(),
        getIt<AutorizacaoService>(),
      ),
    )
    ..registerLazySingleton<OrganizacaoController>(
      () => OrganizacaoController(getIt<OrganizacaoService>()),
    )
    ..registerLazySingleton<QuadroService>(
      () => QuadroService(getIt<SupabaseClient>(), getIt<AutorizacaoService>()),
    )
    ..registerLazySingleton<QuadroController>(
      () => QuadroController(getIt<QuadroService>()),
    )
    ..registerLazySingleton<CartaoService>(
      () => CartaoService(getIt<SupabaseClient>(), getIt<AutorizacaoService>()),
    )
    ..registerLazySingleton<CartaoController>(
      () => CartaoController(getIt<CartaoService>()),
    )
    ..registerLazySingleton<ColunaQuadroService>(
      () => ColunaQuadroService(
        getIt<SupabaseClient>(),
        getIt<AutorizacaoService>(),
      ),
    )
    ..registerLazySingleton<ColunaQuadroController>(
      () => ColunaQuadroController(getIt<ColunaQuadroService>()),
    )
    ..registerLazySingleton<AgendamentoService>(
      () => AgendamentoService(
        getIt<SupabaseClient>(),
        getIt<AutorizacaoService>(),
      ),
    )
    ..registerLazySingleton<AgendamentoController>(
      () => AgendamentoController(getIt<AgendamentoService>()),
    )
    ..registerLazySingleton<UsuarioService>(
      () => UsuarioService(getIt<SupabaseClient>(), getIt<AutorizacaoService>()),
    )
    ..registerLazySingleton<UsuarioController>(
      () => UsuarioController(getIt<UsuarioService>()),
    )
    ..registerLazySingleton<CaptacaoAutomaticaService>(
      () => CaptacaoAutomaticaService(
        getIt<SupabaseClient>(),
        getIt<AutorizacaoService>(),
      ),
    )
    ..registerLazySingleton<CaptacaoAutomaticaController>(
      () => CaptacaoAutomaticaController(getIt<CaptacaoAutomaticaService>()),
    )
    ..registerLazySingleton<ContatoWhatsappResolver>(
      () => ContatoWhatsappResolver(getIt<WppConnectCliente>()),
    )
    ..registerLazySingleton<WebhookWhatsappService>(
      () => WebhookWhatsappService(
        getIt<CaptacaoAutomaticaService>(),
        getIt<ContatoWhatsappResolver>(),
      ),
    )
    ..registerLazySingleton<WebhookWhatsappController>(
      () => WebhookWhatsappController(getIt<WebhookWhatsappService>()),
    )
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerLazySingleton<WppConnectCliente>(
      () => WppConnectCliente(getIt<http.Client>()),
    )
    ..registerLazySingleton<WhatsappService>(
      () => WhatsappService(
        getIt<AutorizacaoService>(),
        getIt<WppConnectCliente>(),
      ),
    )
    ..registerLazySingleton<WhatsappController>(
      () => WhatsappController(getIt<WhatsappService>()),
    );
}
