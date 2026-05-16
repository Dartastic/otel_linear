// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_linear_suppression.dart';

const _tracerName = 'dartastic_otel_libs_linear';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Linear GraphQL query/mutation in a CLIENT span using
/// OTel GraphQL semconv plus Linear-specific fields.
Future<T> tracedLinear<T>({
  required String operationName,
  required Future<T> Function() invoke,
  String? operationType,
  String? teamKey,
  String? issueIdentifier,
}) async {
  if (linearInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'graphql.operation.name': operationName,
    'graphql.operation.type': operationType ?? 'query',
    'linear.operation': operationName,
  };
  if (teamKey != null) m['linear.team.key'] = teamKey;
  if (issueIdentifier != null) {
    m['linear.issue.identifier'] = issueIdentifier;
  }

  final span = _tracer().startSpan(
    'linear $operationName',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
