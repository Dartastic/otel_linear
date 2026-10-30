// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_linear/otel_linear.dart';

/// Traces Linear calls with OpenTelemetry.
///
/// `otel_linear` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Linear call in
/// [tracedLinear]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'linear-example');

  // Wraps a Linear GraphQL query/mutation in a CLIENT span using OTel GraphQL semconv plus Linear-specific fields.
  final linearId = await tracedLinear<String>(
    operationName: 'example',
    operationType: 'standard',
    teamKey: 'orders/2026/inv-1042.pdf',
    issueIdentifier: 'example',
    invoke: () async {
      // Make the Linear call here, then report what it returned.
      return 'linear_8f3a2c';
    },
  );
  OTelLog.info('tracedLinear returned $linearId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLinearInstrumentationAsync.
  await runWithoutLinearInstrumentationAsync(
    () => tracedLinear<String>(
      operationName: 'example',
      operationType: 'standard',
      teamKey: 'orders/2026/inv-1042.pdf',
      issueIdentifier: 'example',
      invoke: () async {
        return 'linear_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
