// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_cloud_functions/otel_cloud_functions.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tracedCloudFunctionCall', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'cloud-functions-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('success emits CLIENT rpc.* span', () async {
      final result = await tracedCloudFunctionCall<int>(
        name: 'addNumbers',
        invoke: () async => 42,
      );
      expect(result, equals(42));

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.client));
      expect(span.name, equals('firebase_functions addNumbers'));
      final attrs = _attrs(span);
      expect(attrs[Rpc.rpcSystemName.key], equals('firebase_functions'));
      expect(
        attrs[Rpc.rpcMethod.key],
        equals('firebase_functions/addNumbers'),
      );
      expect(span.status, isNot(equals(SpanStatusCode.Error)));
    });

    test('FirebaseFunctionsException maps code to error.type', () async {
      Future<int> invoke() async {
        throw FirebaseFunctionsException(
          code: 'not-found',
          message: 'No such function',
        );
      }

      await expectLater(
        tracedCloudFunctionCall<int>(name: 'missingFn', invoke: invoke),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      final span = exporter.spans.single;
      expect(span.status, equals(SpanStatusCode.Error));
      final attrs = _attrs(span);
      expect(attrs[ErrorAttributes.errorType.key], equals('not-found'));
      final events = span.spanEvents ?? [];
      expect(events.any((e) => e.name == 'exception'), isTrue);
    });

    test('generic exception falls back to runtime class', () async {
      await expectLater(
        tracedCloudFunctionCall<int>(
          name: 'boom',
          invoke: () async => throw StateError('nope'),
        ),
        throwsStateError,
      );

      final span = exporter.spans.single;
      expect(
        _attrs(span)[ErrorAttributes.errorType.key],
        equals('StateError'),
      );
    });

    test('runWithoutCloudFunctionsInstrumentationAsync bypasses span creation',
        () async {
      await runWithoutCloudFunctionsInstrumentationAsync(() async {
        await tracedCloudFunctionCall<int>(
          name: 'addNumbers',
          invoke: () async => 1,
        );
      });
      expect(exporter.spans, isEmpty);
    });

    test('span inherits parent when called inside startActiveSpan', () async {
      await OTel.tracer().startActiveSpanAsync<void>(
        name: 'parent',
        fn: (_) async {
          await tracedCloudFunctionCall<int>(
            name: 'addNumbers',
            invoke: () async => 1,
          );
        },
      );

      final parent = exporter.spans.firstWhere((s) => s.name == 'parent');
      final child = exporter.spans.firstWhere(
        (s) => s.name == 'firebase_functions addNumbers',
      );
      expect(
        child.parentSpanContext?.spanId,
        equals(parent.spanContext.spanId),
      );
    });
  });
}
