// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_cloud_functions_suppress;

/// Whether cloud_functions instrumentation is suppressed in the
/// current [Zone] (see [runWithoutCloudFunctionsInstrumentation]).
bool cloudFunctionsInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] in a [Zone] where the traced wrappers become
/// transparent passthroughs (no spans are created).
T runWithoutCloudFunctionsInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutCloudFunctionsInstrumentation].
Future<T> runWithoutCloudFunctionsInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
