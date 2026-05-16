// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_linear/otel_linear.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_linear-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('GraphQL mutation records CLIENT span', () async {
    await tracedLinear<String>(
      operationName: 'CreateIssue',
      operationType: 'mutation',
      teamKey: 'OPS',
      issueIdentifier: 'OPS-42',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('linear CreateIssue')!);
    expect(a['graphql.operation.name'], 'CreateIssue');
    expect(a['graphql.operation.type'], 'mutation');
    expect(a['linear.operation'], 'CreateIssue');
    expect(a['linear.team.key'], 'OPS');
    expect(a['linear.issue.identifier'], 'OPS-42');
  });

  test('suppression skips spans', () async {
    await runWithoutLinearInstrumentationAsync(() async {
      await tracedLinear<String>(
        operationName: 'X',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('linear '), isEmpty);
  });
}
