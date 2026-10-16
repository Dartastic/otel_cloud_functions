# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2-wip]

## [0.2.1] - 2026-10-16

### Changed

- README: standard header naming the instrumented library, its supported platforms and project links; pubspec description to match.

## [0.2.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

## [0.1.0] - 2026-08-08

### Added

- `tracedHttpsCall(HttpsCallable, name:, parameters:)` — wraps an
  [HttpsCallable.call] invocation in a `CLIENT` span named
  `firebase_functions <name>` with
  `rpc.system.name=firebase_functions` and a fully-qualified
  `rpc.method=firebase_functions/<name>`.
- `tracedCloudFunctionCall<R>({name, invoke})` — generic helper
  used internally and exposed for cases where you can't or don't
  want to use a real `HttpsCallable` (testing, custom transports).
- `FirebaseFunctionsException.code`-aware error handling:
  `error.type` is set to the canonical Google Cloud RPC code name
  (`not-found`, `permission-denied`, `unauthenticated`, …).
  Generic exceptions fall back to the runtime class name.
- `runWithoutCloudFunctionsInstrumentation` /
  `runWithoutCloudFunctionsInstrumentationAsync` — zone-scoped
  suppression helpers.
- Tests cover success, FirebaseFunctionsException error path,
  generic exception fallback, suppression scope, and parent-span
  inheritance via `startActiveSpan`.
