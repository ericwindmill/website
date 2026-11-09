// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';

import '../sites.dart';
import '../utils.dart';

final class ServeSiteCommand extends Command<int> {
  @override
  String get description => 'Serve the site locally.';

  @override
  String get name => 'serve';

  ServeSiteCommand() {
    argParser
      ..addFlag(
        'release',
        defaultsTo: false,
        help:
            'Build with compilers used for release builds instead of dartdevc.',
      )
      ..addOption(
        'port',
        abbr: 'p',
        valueHelp: 'port',
        help:
            'The port to serve the site on. '
            "Jaspr's internal web-dev and proxy ports are shifted by "
            'the same offset so multiple servers can run side by side. '
            'Defaults to a per-site port.',
      );
  }

  @override
  Future<int> run() async {
    final release = argResults!.flag('release');
    final selectedSite = this.selectedSite;
    final defaultPorts = selectedSite.jasprPorts;

    final portOption = argResults!.option('port');
    final int portOffset;
    if (portOption == null) {
      portOffset = 0;
    } else if (int.tryParse(portOption) case final port?
        when port > 0 && port <= 65535) {
      portOffset = port - defaultPorts.serve;
    } else {
      stderr.writeln('Invalid --port value: "$portOption".');
      return 64;
    }

    if (installJasprCliIfNecessary() case final jasprInstallResult
        when jasprInstallResult != 0) {
      return jasprInstallResult;
    }

    final jasprPorts = (
      serve: defaultPorts.serve + portOffset,
      webDev: defaultPorts.webDev + portOffset,
      proxy: defaultPorts.proxy + portOffset,
    );
    if ([
      jasprPorts.serve,
      jasprPorts.webDev,
      jasprPorts.proxy,
    ].any((port) => port < 1 || port > 65535)) {
      stderr.writeln(
        'The --port value "$portOption" shifts Jaspr\'s internal ports '
        'out of range: $jasprPorts. Choose a port closer to '
        '${defaultPorts.serve}.',
      );
      return 64;
    }

    final process = await Process.start(
      Platform.resolvedExecutable,
      [
        'pub',
        'global',
        'run',
        'jaspr_cli:jaspr',
        'serve',
        '--port=${jasprPorts.serve}',
        '--web-port=${jasprPorts.webDev}',
        '--proxy-port=${jasprPorts.proxy}',
        '--dart-define=PRODUCTION=false',
        if (release) '--release',
      ],
      workingDirectory: selectedSite.directory,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );

    final processExitCode = await process.exitCode;
    return processExitCode;
  }
}
