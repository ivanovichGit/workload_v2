import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'attrition_predictor.dart';
import 'attrition_schema.dart';

class AttritionPage extends StatefulWidget {
  const AttritionPage({super.key});

  @override
  State<AttritionPage> createState() => _AttritionPageState();
}

class _AttritionPageState extends State<AttritionPage> {
  final _formKey = GlobalKey<FormState>();
  final _predictor = const AttritionPredictor();
  final _salaryFormatter = NumberFormat('#,##0', 'en_US');
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _switchValues = {};
  String _output = '';

  String _formattedFieldValue(
    String key,
    bool isInteger,
    String raw,
    double current,
  ) {
    if (key == 'monthly_salary') {
      final amount = int.tryParse(raw) ?? current.round();
      return 'USD ${_salaryFormatter.format(amount)}';
    }
    if (isInteger) {
      return raw.isEmpty ? '0' : raw;
    }
    return raw.isEmpty ? '0.0' : raw;
  }

  String _sliderValueLabel(String key, bool isInteger, double value) {
    if (key == 'monthly_salary') {
      return 'USD ${_salaryFormatter.format(value.round())}';
    }
    if (isInteger) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    for (final field in attritionSchema) {
      if (field.type == FormFieldType.boolean) {
        _switchValues[field.key] = false;
        continue;
      }

      final controller = TextEditingController();
      if (field.type == FormFieldType.dropdown && field.options.isNotEmpty) {
        controller.text = field.options.first;
      }
      if (field.type == FormFieldType.integer ||
          field.type == FormFieldType.decimal) {
        final min = attritionRanges[field.key]?[0] ?? 0;
        controller.text = field.type == FormFieldType.integer
            ? min.round().toString()
            : min.toString();
      }
      _controllers[field.key] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(FieldSpec field, String? text) {
    if (field.type == FormFieldType.integer ||
        field.type == FormFieldType.decimal) {
      if (text == null || text.isEmpty) {
        return 'Required';
      }

      final parsed = field.type == FormFieldType.integer
          ? int.tryParse(text)
          : double.tryParse(text);

      if (parsed == null) {
        return 'Invalid number';
      }

      final range = attritionRanges[field.key];
      if (range != null) {
        final value = parsed.toDouble();
        if (value < range[0] || value > range[1]) {
          return 'Out of range [${range[0]} - ${range[1]}]';
        }
      }
    }

    if (field.type == FormFieldType.text && (text == null || text.isEmpty)) {
      return 'Required';
    }

    return null;
  }

  Map<String, dynamic> _collectInput() {
    final input = <String, dynamic>{};

    for (final field in attritionSchema) {
      if (field.type == FormFieldType.boolean) {
        input[field.key] = _switchValues[field.key] ?? false;
        continue;
      }

      final text = _controllers[field.key]?.text ?? '';
      switch (field.type) {
        case FormFieldType.integer:
          input[field.key] = int.tryParse(text);
          break;
        case FormFieldType.decimal:
          input[field.key] = double.tryParse(text);
          break;
        default:
          input[field.key] = text.isEmpty ? null : text;
      }
    }

    return input;
  }

  Widget _buildField(FieldSpec field) {
    final key = field.key;
    final controller = _controllers[key];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    if (field.type == FormFieldType.dropdown) {
      return DropdownButtonFormField<String>(
        initialValue: controller.text,
        items: field.options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) {
          setState(() => controller.text = value ?? '');
        },
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (field.type == FormFieldType.text) {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => _validate(field, value),
      );
    }

    if (field.type == FormFieldType.integer ||
        field.type == FormFieldType.decimal) {
      final range = attritionRanges[key] ?? const [0.0, 100.0];
      final min = range[0];
      final max = range[1];
      final isInteger = field.type == FormFieldType.integer;
      final current = double.tryParse(controller.text) ?? min;
      final step = isInteger ? 1.0 : 0.1;
      final divisions = ((max - min) / step).round();

      return InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        child: Column(
          children: [
            Slider(
              value: current.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions > 0 ? divisions : null,
              label: _sliderValueLabel(key, isInteger, current),
              onChanged: (value) {
                setState(() {
                  if (isInteger) {
                    controller.text = value.round().toString();
                  } else {
                    final text = value.toStringAsFixed(1);
                    controller.text = text.endsWith('.0')
                        ? text.substring(0, text.length - 2)
                        : text;
                  }
                });
              },
            ),
            Text(
              _formattedFieldValue(key, isInteger, controller.text, current),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildRows(List<FieldSpec> fields) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      final left = _buildField(fields[i]);
      final right = i + 1 < fields.length
          ? _buildField(fields[i + 1])
          : const SizedBox.shrink();

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 10),
              Expanded(child: right),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _output = 'Error de validación: corrige los campos resaltados.';
      });
      return;
    }

    setState(() {
      _output = 'Ejecutando inferencia...';
    });

    final result = await _predictor.predict(_collectInput());
    setState(() {
      _output = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoricalFields = attritionSchema
        .where(
          (field) =>
              field.type != FormFieldType.integer &&
              field.type != FormFieldType.decimal,
        )
        .toList();

    final numericFields = attritionSchema
        .where(
          (field) =>
              field.type == FormFieldType.integer ||
              field.type == FormFieldType.decimal,
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicción de Deserción Laboral',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Analiza el riesgo de rotación a partir del perfil laboral.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Perfil laboral',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._buildRows(categoricalFields),
                    const SizedBox(height: 14),
                    Text(
                      'Indicadores cuantitativos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._buildRows(numericFields),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Predecir'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Resultado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _output.isEmpty ? 'Sin resultado aún' : _output,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
