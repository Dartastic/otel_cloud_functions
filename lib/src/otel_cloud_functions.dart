// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'cloud_functions_suppression.dart';

const _tracerName = 'otel_cloud_functions';
const _rpcSystem = 'firebase_functions';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

Attributes _baseAttrs(String functionName) =>
    OTel.attributesFromMap(<String, Object>{
      RPC.rpcSystem.key: _rpcSystem,
      RPC.rpcService.key: _rpcSystem,
      RPC.rpcMethod.key: functionName,
    });

/// Generic helper. Opens a CLIENT span with `rpc.system =
/// firebase_functions` and `rpc.method = [name]`, runs [invoke],
/// and flips the span to Error on exception (recordException →
/// setStatus). Suitable for testing without constructing a real
/// [HttpsCallable]; [tracedHttpsCall] uses it under the hood.
Future<R> tracedCloudFunctionCall<R>({
  required String name,
  required Future<R> Function() invoke,
}) async {
  if (cloudFunctionsInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'firebase_functions $name',
    kind: SpanKind.client,
    attributes: _baseAttrs(name),
  );
  try {
    return await invoke();
  } on FirebaseFunctionsException catch (e, st) {
    span.addAttributes(OTel.attributes([
      // Firebase Functions exposes its status as a string
      // ('not-found', 'permission-denied', etc.) — the canonical
      // Google Cloud RPC code names.
      OTel.attributeString(ErrorResource.errorType.key, e.code),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.message ?? e.code);
    rethrow;
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

/// Traced wrapper around [HttpsCallable.call].
///
/// Opens a CLIENT span named `firebase_functions <name>` with
/// `rpc.system=firebase_functions` and `rpc.method=<name>`. The
/// function name has to be passed in because [HttpsCallable] does
/// not expose it after construction.
///
/// On [FirebaseFunctionsException], `error.type` is set to the
/// `code` (`not-found`, `permission-denied`, ...) which matches
/// Google Cloud's canonical RPC status codes.
Future<HttpsCallableResult<dynamic>> tracedHttpsCall(
  HttpsCallable callable, {
  required String name,
  dynamic parameters,
}) {
  return tracedCloudFunctionCall<HttpsCallableResult<dynamic>>(
    name: name,
    invoke: () => callable.call(parameters),
  );
}
