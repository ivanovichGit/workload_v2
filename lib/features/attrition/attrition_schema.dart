enum FormFieldType { dropdown, integer, decimal, text, boolean }

class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
  });

  final String key;
  final String label;
  final FormFieldType type;
  final List<String> options;
}

/// Orden exacto para el vector ONNX (15 valores):
/// [0-5]: features numéricos (6 valores)
/// [6-11]: one-hot encoding departamento (6 valores)
/// [12-14]: one-hot encoding nivel de rol (3 valores)
const List<FieldSpec> attritionSchema = [
  // Features numéricos en orden del modelo
  FieldSpec(
    key: 'monthly_salary',
    label: 'Salario Mensual (USD)',
    type: FormFieldType.integer,
  ),
  FieldSpec(
    key: 'avg_weekly_hours',
    label: 'Horas Semanales Promedio',
    type: FormFieldType.integer,
  ),
  FieldSpec(
    key: 'projects_handled',
    label: 'Proyectos Asignados',
    type: FormFieldType.integer,
  ),
  FieldSpec(
    key: 'performance_rating',
    label: 'Evaluación de Desempeño',
    type: FormFieldType.integer,
  ),
  FieldSpec(
    key: 'absences_days',
    label: 'Días de Ausencia',
    type: FormFieldType.integer,
  ),
  FieldSpec(
    key: 'job_satisfaction',
    label: 'Satisfacción Laboral',
    type: FormFieldType.integer,
  ),
  // Features categóricos
  FieldSpec(
    key: 'department',
    label: 'Departamento',
    type: FormFieldType.dropdown,
    options: [
      'Engineering',
      'Finance',
      'HR',
      'Marketing',
      'Operations',
      'Sales',
    ],
  ),
  FieldSpec(
    key: 'role_level',
    label: 'Nivel de Rol',
    type: FormFieldType.dropdown,
    options: ['Junior', 'Mid', 'Senior'],
  ),
];

const Map<String, List<double>> attritionRanges = {
  'monthly_salary': [30000, 120000],
  'avg_weekly_hours': [35, 65],
  'projects_handled': [1, 8],
  'performance_rating': [1, 5],
  'absences_days': [0, 20],
  'job_satisfaction': [1, 5],
};

/// Departamentos en orden de one-hot encoding
const List<String> departments = [
  'Engineering',
  'Finance',
  'HR',
  'Marketing',
  'Operations',
  'Sales',
];

/// Niveles de rol en orden de one-hot encoding
const List<String> roleLevels = ['Junior', 'Mid', 'Senior'];
