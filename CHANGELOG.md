# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
