import 'dart:math' show exp;
import '../../onnx_interop.dart';
import 'attrition_schema.dart';

class AttritionPredictor {
  const AttritionPredictor();

  /// Se construye un vector exacto de 15 floats con one-hot encoding
  /// Orden obligatorio:
  /// [0-5]: numeric (6 valores)
  /// [6-11]: department one-hot (6 valores)  
  /// [12-14]: role_level one-hot (3 valores)
  List<double> _buildInputVector(Map<String, dynamic> input) {
    final vector = <double>[];

    // Se agregan valores numéricos (posiciones 0-5)
    vector.add((input['monthly_salary'] as num?)?.toDouble() ?? 0.0);
    vector.add((input['avg_weekly_hours'] as num?)?.toDouble() ?? 0.0);
    vector.add((input['projects_handled'] as num?)?.toDouble() ?? 0.0);
    vector.add((input['performance_rating'] as num?)?.toDouble() ?? 0.0);
    vector.add((input['absences_days'] as num?)?.toDouble() ?? 0.0);
    vector.add((input['job_satisfaction'] as num?)?.toDouble() ?? 0.0);

    // Se agrega one-hot encoding para departamento (posiciones 6-11)
    final department = (input['department'] as String?) ?? '';
    for (final dept in departments) {
      vector.add(department == dept ? 1.0 : 0.0);
    }

    // Se agrega one-hot encoding para nivel de rol (posiciones 12-14)
    final roleLevel = (input['role_level'] as String?) ?? '';
    for (final role in roleLevels) {
      vector.add(roleLevel == role ? 1.0 : 0.0);
    }

    assert(
      vector.length == 15,
      'Vector debe tener exactamente 15 elementos, tiene ${vector.length}',
    );

    return vector;
  }

  /// Se aplica la función sigmoid a un valor
  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  Future<String> predict(Map<String, dynamic> input) async {
    try {
      // Se construye el vector de 15 floats
      final vector = _buildInputVector(input);

      // Se ejecuta la inferencia ONNX con el vector
      final outputs = await runOnnxInference({
        'input_vector': vector,
        'department': input['department'] ?? '',
        'role_level': input['role_level'] ?? '',
      });

      // Se extrae el logit de la salida
      final logit = _extractLogit(outputs);

      // Se aplica sigmoid al logit
      final probability = _sigmoid(logit);

      // Se clasifica el resultado
      final isAttrition = probability >= 0.5;
      final percentage = (probability * 100).toStringAsFixed(1);

      if (isAttrition) {
        return 'Riesgo ALTO de abandono ($percentage% de probabilidad)';
      } else {
        return 'Riesgo BAJO de abandono ($percentage% de probabilidad)';
      }
    } catch (e) {
      return 'Error en inferencia: ${e.toString()}';
    }
  }

  /// Se extrae el valor de logit de la salida ONNX
  double _extractLogit(Map<String, dynamic> outputs) {
    if (outputs.isEmpty) {
      return 0.0;
    }

    final firstValue = outputs[outputs.keys.first];

    // En caso de string numérico, se parsea el valor
    if (firstValue is String) {
      return double.tryParse(firstValue) ?? 0.0;
    }

    // En caso de número, se convierte a double
    if (firstValue is num) {
      return firstValue.toDouble();
    }

    // En caso de lista, se extrae el primer elemento
    if (firstValue is List && firstValue.isNotEmpty) {
      final first = firstValue[0];
      if (first is num) {
        return first.toDouble();
      }
    }

    return 0.0;
  }
}
