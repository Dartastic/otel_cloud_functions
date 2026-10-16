<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `cloud_functions`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_cloud_functions` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `cloud_functions` that
easily adds standard observability to applications that use `cloud_functions`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, macOS and Web, for versions of `cloud_functions` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

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
  - `rpc.system.name = firebase_functions`
  - `rpc.method = firebase_functions/<function name>` (the registry
    expects `rpc.method` to be fully qualified)
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
