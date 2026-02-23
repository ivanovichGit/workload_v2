import '../../onnx_interop.dart';

class AttritionPredictor {
  const AttritionPredictor();

  Future<String> predict(Map<String, dynamic> input) async {
    try {
      final outputs = await runOnnxInference(input);
      final rawLabel = _extractLabel(outputs);
      return _toReadableResult(rawLabel);
    } catch (_) {
      return 'No se pudo ejecutar la inferencia.';
    }
  }

  String _extractLabel(Map<String, dynamic> outputs) {
    if (outputs.isEmpty) {
      return 'Unknown';
    }

    final value = outputs[outputs.keys.first];

    if (value is String) {
      return value;
    }

    if (value is List) {
      if (value.isEmpty) {
        return 'Unknown';
      }

      if (value.every((item) => item is num)) {
        final scores = value
            .map((item) => (item as num).toDouble())
            .toList(growable: false);

        var bestIndex = 0;
        for (var i = 1; i < scores.length; i++) {
          if (scores[i] > scores[bestIndex]) {
            bestIndex = i;
          }
        }

        const labels = ['No', 'Yes'];
        return bestIndex < labels.length ? labels[bestIndex] : 'Unknown';
      }

      if (value.every((item) => item is String)) {
        return value.first as String;
      }

      return value.first.toString();
    }

    return 'Unknown';
  }

  String _toReadableResult(String rawLabel) {
    final normalized = rawLabel.trim().toLowerCase();

    if (normalized == 'yes') {
      return 'Riesgo alto de abandono ("Yes")';
    }

    if (normalized == 'no') {
      return 'Riesgo bajo de abandono ("No")';
    }

    return 'Resultado del modelo: "$rawLabel"';
  }
}
