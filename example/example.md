# otel_cloud_functions example

```dart
// example/lib/main.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:otel_cloud_functions/otel_cloud_functions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bring up Firebase and OTel before the first callable fires.
  await Firebase.initializeApp();
  await OTel.initialize(
    serviceName: 'cloud-functions-demo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SumPage());
  }
}

class SumPage extends StatefulWidget {
  const SumPage({super.key});

  @override
  State<SumPage> createState() => _SumPageState();
}

class _SumPageState extends State<SumPage> {
  int? _sum;

  Future<void> _add() async {
    final callable = FirebaseFunctions.instance.httpsCallable('addNumbers');

    // ✨ Span: `firebase_functions addNumbers` (CLIENT)
    //
    //    rpc.system.name = firebase_functions
    //    rpc.method      = firebase_functions/addNumbers
    //
    //    On FirebaseFunctionsException the span status flips to Error
    //    and error.type carries the canonical RPC code name
    //    (`not-found`, `permission-denied`, ...).
    final result = await tracedHttpsCall(
      callable,
      name: 'addNumbers',
      parameters: {'a': 1, 'b': 2},
    );

    setState(() => _sum = result.data as int);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('sum: ${_sum ?? '?'}')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Without a real `HttpsCallable`

If you can't construct one (tests, mock backends, custom
transports), use the lower-level helper directly:

```dart
final result = await tracedCloudFunctionCall<MyResult>(
  name: 'myFunction',
  invoke: () => fakeBackend.invokeMyFunction(params),
);
```

## Trace shape

```
tap FloatingActionButton
  firebase_functions addNumbers          (CLIENT)
    rpc.system.name = firebase_functions
    rpc.method      = firebase_functions/addNumbers
```
