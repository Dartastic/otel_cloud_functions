# otel_cloud_functions

OpenTelemetry instrumentation for
[`package:cloud_functions`](https://pub.dev/packages/cloud_functions)
(Firebase Cloud Functions callable functions), built on the
[Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry).

Wrap an `HttpsCallable.call(...)` invocation to get a `CLIENT` span
with `rpc.*` semconv attributes.

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:otel_cloud_functions/otel_cloud_functions.dart';

final callable = FirebaseFunctions.instance.httpsCallable('addNumbers');

final result = await tracedHttpsCall(
  callable,
  name: 'addNumbers',
  parameters: {'a': 1, 'b': 2},
);

final sum = result.data as int;
```

The function name has to be passed explicitly because
`HttpsCallable` does not expose it after construction.

## Span shape

- **Span name**: `firebase_functions <function name>`
- **Span kind**: `CLIENT`
- **Attributes**:
  - `rpc.system = firebase_functions`
  - `rpc.service = firebase_functions`
  - `rpc.method = <function name>`
- **Span status**: `Error` on `FirebaseFunctionsException` or any
  other thrown error. For `FirebaseFunctionsException`,
  `error.type` is set to the `code` field (e.g. `not-found`,
  `permission-denied`, `unauthenticated`, `internal`) — these are
  the canonical Google Cloud RPC code names, much better for
  alerting than the runtime class name.
- Spans inherit the surrounding active span as parent, so
  callable invocations inside `Tracer.startActiveSpan` nest
  naturally.

## Lower-level helper

If you can't construct a real `HttpsCallable` (testing, mock
backends, custom transports), use `tracedCloudFunctionCall`
directly:

```dart
final result = await tracedCloudFunctionCall<MyResult>(
  name: 'myFunction',
  invoke: () => fakeBackend.invokeMyFunction(params),
);
```

`tracedHttpsCall` is a thin wrapper over this.

## Self-recursion guard

```dart
await runWithoutCloudFunctionsInstrumentationAsync(() async {
  await tracedHttpsCall(callable, name: 'fn');
});
```

Inside the helper's zone, the traced wrappers become transparent
passthroughs.

## Caveats

- `HttpsCallable` does not expose the function name, so you must
  pass it as a named parameter to `tracedHttpsCall`. This is
  awkward but is the cost of `cloud_functions` not surfacing the
  name from its private constructor.
- Streaming callables (`HttpsCallable.stream`) aren't wrapped
  here yet — the streaming response shape needs different span
  semantics (one span per chunk? one for the stream?). Open an
  issue if you need this.
- The wrapper calls `OTel.tracerProvider().getTracer(...)` on each
  invocation — `OTel.initialize()` must have run first.

## License

Apache 2.0 — see `LICENSE`.
