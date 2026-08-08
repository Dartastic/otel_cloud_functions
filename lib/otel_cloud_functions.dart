// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry instrumentation for `package:cloud_functions`.
///
/// Use [tracedHttpsCall] to wrap an [HttpsCallable.call] invocation
/// in a `CLIENT` span with `rpc.system.name=firebase_functions`.
library;

export 'src/cloud_functions_suppression.dart';
export 'src/otel_cloud_functions.dart';
