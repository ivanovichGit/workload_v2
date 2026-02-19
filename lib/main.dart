import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onnx_interop.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // ESQUEMA DE DATOS — Campos del modelo

  final List<Map<String, dynamic>> _schema = [
    {
      'key': 'department',
      'label': 'Departamento',
      'type': 'dropdown',
      'options': [
        'Engineering',
        'HR',
        'Finance',
        'Marketing',
        'Sales',
        'Operations',
      ],
    },
    {
      'key': 'role_level',
      'label': 'Nivel de Rol',
      'type': 'dropdown',
      'options': ['Junior', 'Mid', 'Senior'],
    },
    {'key': 'monthly_salary', 'label': 'Salario Mensual', 'type': 'int'},
    {
      'key': 'avg_weekly_hours',
      'label': 'Horas Semanales Promedio',
      'type': 'int',
    },
    {'key': 'projects_handled', 'label': 'Proyectos Asignados', 'type': 'int'},
    {
      'key': 'performance_rating',
      'label': 'Evaluación de Desempeño',
      'type': 'int',
    },
    {'key': 'absences_days', 'label': 'Días de Ausencia', 'type': 'int'},
    {'key': 'job_satisfaction', 'label': 'Satisfacción Laboral', 'type': 'int'},
  ];

  // RANGOS para Sliders numéricos [min, max]

  final Map<String, List<double>> _ranges = {
    'monthly_salary': [30000, 120000],
    'avg_weekly_hours': [35, 65],
    'projects_handled': [1, 8],
    'performance_rating': [1, 5],
    'absences_days': [0, 20],
    'job_satisfaction': [1, 5],
  };

  // Sin campos opcionales ni booleanos en este modelo
  final Set<String> _optionalNumeric = {};
  final Set<String> _symptomKeys = {};

  // Variables de estado

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _bools = {};
  String _output = '';

  @override
  void initState() {
    super.initState();
    for (var f in _schema) {
      if (f['type'] == 'bool') {
        _bools[f['key']] = false;
      } else {
        _controllers[f['key']] = TextEditingController();
      }
      // Para dropdowns, inicializar con la primera opción
      if (f['type'] == 'dropdown' && (f['options'] as List).isNotEmpty) {
        _controllers[f['key']]!.text = (f['options'] as List).first;
      }
      // Para numéricos, inicializar con el mínimo del rango
      if (f['type'] == 'int' || f['type'] == 'double') {
        final min = _ranges.containsKey(f['key']) ? _ranges[f['key']]![0] : 0.0;
        final isInt = f['type'] == 'int';
        _controllers[f['key']]!.text = isInt
            ? min.round().toString()
            : min.toString();
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Validación
  String? _validateField(String key, String type, String? txt) {
    if (type == 'int' || type == 'double') {
      if (txt == null || txt.isEmpty) {
        if (_optionalNumeric.contains(key)) return null;
        return 'Required';
      }
      final num? parsed = type == 'int'
          ? int.tryParse(txt)
          : double.tryParse(txt);
      if (parsed == null) return 'Invalid number';
      if (_ranges.containsKey(key)) {
        final min = _ranges[key]![0];
        final max = _ranges[key]![1];
        if (parsed.toDouble() < min || parsed.toDouble() > max)
          return 'Out of range [$min - $max]';
      }
      return null;
    } else {
      if (type == 'string' && (txt == null || txt.isEmpty)) return 'Required';
      return null;
    }
  }

  // Recolectar valores

  Map<String, dynamic> _collectValues() {
    final Map<String, dynamic> m = {};
    for (var f in _schema) {
      final k = f['key'] as String;
      final t = f['type'] as String;
      if (t == 'bool') {
        m[k] = _bools[k];
      } else {
        final txt = _controllers[k]!.text;
        if (t == 'int')
          m[k] = int.tryParse(txt);
        else if (t == 'double')
          m[k] = double.tryParse(txt);
        else
          m[k] = txt.isEmpty ? null : txt;
      }
    }
    return m;
  }

  // Inferencia ONNX

  Future<String> runInference(Map<String, dynamic> input) async {
    try {
      final res = await runOnnxInference(input);
      if (res.isEmpty) return 'Unknown';
      final firstKey = res.keys.first;
      final out = res[firstKey];

      // Etiquetas de salida: clasificación binaria de attrition
      const labels = ['No', 'Yes'];

      if (out is String) return out;

      if (out is List) {
        if (out.isEmpty) return 'Unknown';
        // Si todos son números → argmax para obtener la etiqueta
        if (out.every((e) => e is num)) {
          final values = List<double>.from(
            out.map((e) => (e as num).toDouble()),
          );
          int argmax = 0;
          for (int i = 1; i < values.length; i++) {
            if (values[i] > values[argmax]) argmax = i;
          }
          return argmax < labels.length ? labels[argmax] : 'Index $argmax';
        }
        // Si todos son strings, usar el primero
        if (out.every((e) => e is String)) return out.first as String;
        return out.first.toString();
      }
      return 'Unknown';
    } catch (e) {
      return 'Error';
    }
  }

  // BUILD — UI

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workload Attrition Predictor',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFDCEEFB),
        primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.blueAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              margin: const EdgeInsets.all(24),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        //  TÍTULO
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Predicción de Deserción Laboral',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),

                        // CAMPOS DEL FORMULARIO
                        Builder(
                          builder: (ctx) {
                            Widget fieldWidget(Map<String, dynamic> f) {
                              final k = f['key'] as String;
                              final t = f['type'] as String;
                              final label = f['label'] as String;

                              if (t == 'dropdown') {
                                final opts = List<String>.from(
                                  f['options'] as List,
                                );
                                return DropdownButtonFormField<String>(
                                  value: _controllers[k]!.text,
                                  items: opts
                                      .map(
                                        (o) => DropdownMenuItem(
                                          value: o,
                                          child: Text(o),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _controllers[k]!.text = v ?? '',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: label,
                                    border: const OutlineInputBorder(),
                                  ),
                                );
                              } else if (t == 'string') {
                                return TextFormField(
                                  controller: _controllers[k],
                                  decoration: InputDecoration(
                                    labelText: label,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) => _validateField(k, t, v),
                                );
                              } else if (t == 'int' || t == 'double') {
                                final min = _ranges.containsKey(k)
                                    ? _ranges[k]![0]
                                    : 0.0;
                                final max = _ranges.containsKey(k)
                                    ? _ranges[k]![1]
                                    : 100.0;
                                final isInt = t == 'int';
                                final double current =
                                    double.tryParse(_controllers[k]!.text) ??
                                    min;
                                final step = isInt ? 1.0 : 0.1;
                                final divisions = ((max - min) / step).round();
                                return InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: label,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: Column(
                                    children: [
                                      Slider(
                                        value: current.clamp(min, max),
                                        min: min,
                                        max: max,
                                        divisions: divisions > 0
                                            ? divisions
                                            : null,
                                        label: isInt
                                            ? current.round().toString()
                                            : current.toStringAsFixed(1),
                                        onChanged: (v) => setState(() {
                                          if (isInt) {
                                            _controllers[k]!.text = v
                                                .round()
                                                .toString();
                                          } else {
                                            final s = v.toStringAsFixed(1);
                                            _controllers[k]!.text =
                                                s.endsWith('.0')
                                                ? s.substring(0, s.length - 2)
                                                : s;
                                          }
                                        }),
                                      ),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          isInt
                                              ? _controllers[k]!.text
                                              : _controllers[k]!.text.isEmpty
                                              ? '0.0'
                                              : _controllers[k]!.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            // Separar campos: no-numéricos y numéricos
                            final nonNumeric = _schema
                                .where(
                                  (f) =>
                                      !_symptomKeys.contains(f['key']) &&
                                      f['type'] != 'int' &&
                                      f['type'] != 'double',
                                )
                                .toList();
                            final numeric = _schema
                                .where(
                                  (f) =>
                                      !_symptomKeys.contains(f['key']) &&
                                      (f['type'] == 'int' ||
                                          f['type'] == 'double'),
                                )
                                .toList();

                            final List<Widget> out = [];

                            // Campos NO-NUMÉRICOS en filas de 2 columnas
                            for (var i = 0; i < nonNumeric.length; i += 2) {
                              final a = fieldWidget(nonNumeric[i]);
                              final b = i + 1 < nonNumeric.length
                                  ? fieldWidget(nonNumeric[i + 1])
                                  : const SizedBox.shrink();
                              out.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: a),
                                      const SizedBox(width: 12),
                                      Expanded(child: b),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Campos NUMÉRICOS (Sliders) en filas de 2 columnas
                            for (var i = 0; i < numeric.length; i += 2) {
                              final a = fieldWidget(numeric[i]);
                              final b = i + 1 < numeric.length
                                  ? fieldWidget(numeric[i + 1])
                                  : const SizedBox.shrink();
                              out.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: a),
                                      const SizedBox(width: 12),
                                      Expanded(child: b),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(children: out);
                          },
                        ),

                        const SizedBox(height: 12),

                        // 3. BOTÓN
                        ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              setState(() {
                                _output =
                                    'Error de validación: corrige los campos resaltados.';
                              });
                              return;
                            }
                            final values = _collectValues();
                            setState(
                              () => _output = 'Ejecutando inferencia...',
                            );
                            final result = await runInference(values);
                            setState(() => _output = result);
                          },
                          child: const Text('Enviar y Predecir'),
                        ),

                        const SizedBox(height: 20),

                        // RESULTADO
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Resultado:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          child: _output.isEmpty
                              ? const Text('Sin resultado aún')
                              : Text(
                                  _output,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
