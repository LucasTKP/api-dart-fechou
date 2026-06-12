import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:kanban_api/config/ambiente.dart';
import 'package:kanban_api/config/injecao_dependencia.dart';

Future<void> init(InternetAddress ip, int port) async {
  print('Iniciando o servidor...');
  Ambiente.carregar();
  configurarInjecaoDependencia();
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  // ignore: avoid_print
  print('Running on $ip:$port');
  return serve(handler, ip, port);
}
