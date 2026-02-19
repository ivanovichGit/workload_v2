@JS()
library onnx_interop;

import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:js/js.dart';

@JS('runOnnxInference')
external dynamic _runOnnxInference(dynamic input);

Future<Map<String, dynamic>> runOnnxInference(
  Map<String, dynamic> inputs,
) async {
  final jsObj = js_util.jsify(inputs);
  final res = _runOnnxInference(jsObj);
  final futureLike = js_util.promiseToFuture(res);
  final decoded = await futureLike;
  return Map<String, dynamic>.from(js_util.dartify(decoded) as Map);
}
