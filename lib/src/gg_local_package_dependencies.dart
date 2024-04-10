// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'commands/graph.dart';
import 'package:gg_log/gg_log.dart';

/// The command line interface for GgLocalPackageDependencies
class GgLocalPackageDependencies extends Command<dynamic> {
  /// Constructor
  GgLocalPackageDependencies({required this.ggLog}) {
    addSubcommand(Graph(ggLog: ggLog));
  }

  /// The log function
  final GgLog ggLog;

  // ...........................................................................
  @override
  final name = 'ggLocalPackageDependencies';
  @override
  final description = 'Add your description here.';
}
