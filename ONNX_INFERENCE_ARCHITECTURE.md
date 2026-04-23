# Arquitectura de Inferencia ONNX - Workload Attrition Predictor

## Resumen de Cambios

Se ha verificado y corregido todo el proyecto para asegurar que la inferencia con el modelo ONNX funcione correctamente según las especificaciones.

---

## Estructura de Entrada (Obligatoria)

El modelo espera exactamente **15 valores float32** en este orden preciso:

```
Posición  | Campo                    | Tipo    | Rango
----------|--------------------------|---------|----------
[0]       | monthly_salary           | float32 | 30000-120000
[1]       | avg_weekly_hours         | float32 | 35-65
[2]       | projects_handled         | float32 | 1-8
[3]       | performance_rating       | float32 | 1-5
[4]       | absences_days            | float32 | 0-20
[5]       | job_satisfaction         | float32 | 1-5
[6-11]    | department (one-hot)     | float32 | 0 ó 1
[12-14]   | role_level (one-hot)     | float32 | 0 ó 1
```

### Departamentos (One-Hot, 6 valores):
```
[6]   department_Engineering   (1 si Engineering, 0 si no)
[7]   department_Finance       (1 si Finance, 0 si no)
[8]   department_HR            (1 si HR, 0 si no)
[9]   department_Marketing     (1 si Marketing, 0 si no)
[10]  department_Operations    (1 si Operations, 0 si no)
[11]  department_Sales         (1 si Sales, 0 si no)
```

### Niveles de Rol (One-Hot, 3 valores):
```
[12]  role_level_Junior  (1 si Junior, 0 si no)
[13]  role_level_Mid     (1 si Mid, 0 si no)
[14]  role_level_Senior  (1 si Senior, 0 si no)
```

---

## Flujo de Datos

### Interfaz Flutter → Backend Dart

**Archivo:** [`lib/features/attrition/attrition_page.dart`](lib/features/attrition/attrition_page.dart)

- El usuario completa el formulario con 8 campos
- `_collectInput()` retorna un `Map<String, dynamic>` con claves:
  - `monthly_salary` (int)
  - `avg_weekly_hours` (int)
  - `projects_handled` (int)
  - `performance_rating` (int)
  - `absences_days` (int)
  - `job_satisfaction` (int)
  - `department` (String)
  - `role_level` (String)

### Construcción del Vector

**Archivo:** [`lib/features/attrition/attrition_predictor.dart`](lib/features/attrition/attrition_predictor.dart)

Método: `_buildInputVector(Map<String, dynamic> input) → List<double>`

```dart
List<double> vector = [
  // Valores numéricos (posiciones 0-5, sin normalización)
  monthlySalary,
  avgWeeklyHours,
  projectsHandled,
  performanceRating,
  absencesDays,
  jobSatisfaction,

  // One-hot encoding departamento (posiciones 6-11)
  department == "Engineering" ? 1.0 : 0.0,
  department == "Finance" ? 1.0 : 0.0,
  department == "HR" ? 1.0 : 0.0,
  department == "Marketing" ? 1.0 : 0.0,
  department == "Operations" ? 1.0 : 0.0,
  department == "Sales" ? 1.0 : 0.0,

  // One-hot encoding nivel de rol (posiciones 12-14)
  roleLevel == "Junior" ? 1.0 : 0.0,
  roleLevel == "Mid" ? 1.0 : 0.0,
  roleLevel == "Senior" ? 1.0 : 0.0,
];
```

### Comunicación Dart ↔ JavaScript

**Dart:** [`lib/onnx_interop.dart`](lib/onnx_interop.dart)
- Se invoca JavaScript con: `runOnnxInference(inputMap)`

**JavaScript:** [`web/onnx_loader.js`](web/onnx_loader.js)
- Se recibe el objeto con `input_vector: [15 floats]`
- Se valida que sean exactamente 15 elementos
- Se crea tensor Float32 con shape `[1, 15]`
- Se ejecuta la sesión ONNX

### Inferencia ONNX

**Archivo:** [`web/onnx_loader.js`](web/onnx_loader.js)

```javascript
// Se valida el vector
if (vector.length !== 15) {
  throw new Error(`Vector debe tener 15 elementos, tiene ${vector.length}`);
}

// Se crea el tensor
const inputTensor = new ort.Tensor('float32', Float32Array(vector), [1, 15]);

// Se ejecuta el modelo
results = await session.run(feeds);
```

### Procesamiento de Salida

**Archivo:** [`lib/features/attrition/attrition_predictor.dart`](lib/features/attrition/attrition_predictor.dart)

```dart
// Se extrae el logit de la salida ONNX
double logit = extractLogit(outputs);

// Se aplica sigmoid
double probability = 1.0 / (1.0 + exp(-logit));

// Se clasifica el resultado
if (probability >= 0.5) {
  return 'Riesgo ALTO de abandono (${(probability*100).toStringAsFixed(1)}%)';
} else {
  return 'Riesgo BAJO de abandono (${(probability*100).toStringAsFixed(1)}%)';
}
```

---

## Puntos Críticos

### Normalización
- Flutter NO normaliza los datos numéricos
- El modelo ONNX contiene un `Preprocessor` interno que aplica normalización
- Los valores se envían sin procesar (raw)

### One-Hot Encoding
- Se implementa en ambos lados:
  - Dart: `_buildInputVector()`
  - JavaScript: `_buildInputVector()` (como fallback)

### Sigmoid
- Se aplica en Dart después de recibir el logit
- Convierte logit → probabilidad [0, 1]
- Umbral: 0.5 para clasificación High/Low

### Orden Exacto
- El vector debe ser: `[6 numeric + 6 department + 3 role_level]`
- Cualquier otro orden causará predicciones incorrectas

---

## Checklist de Validación

- [x] Schema define 8 campos en orden correcto
- [x] Constantes `departments` y `roleLevels` exportadas
- [x] `_buildInputVector()` crea exactamente 15 floats
- [x] One-hot encoding correcto (Dart)
- [x] Sigmoid aplicado a logit
- [x] JavaScript valida vector length === 15
- [x] Tensor Float32 con shape [1, 15]
- [x] Logging habilitado para debugging
- [x] Sin errores de compilación Dart

---

## Cómo Probar

1. **Ejecutar la app:**
   ```bash
   flutter run -d chrome
   ```

2. **Completar el formulario** con valores válidos

3. **Verificar logs en browser (F12):**
   ```
   "Input vector (15 floats):" [6 numeric + 6 dept + 3 role]
   "Running inference with input shape [1, 15]..."
   "ONNX output:" [logit_value]
   ```

4. **Resultado esperado:**
   ```
   Riesgo ALTO de abandono (85.3% de probabilidad)
   o
   Riesgo BAJO de abandono (23.7% de probabilidad)
   ```

---

## Archivos Modificados

1. **[lib/features/attrition/attrition_schema.dart](lib/features/attrition/attrition_schema.dart)**
   - Se reordenan campos (numeric first, categorical last)
   - Se agregan constantes `departments` y `roleLevels`

2. **[lib/features/attrition/attrition_predictor.dart](lib/features/attrition/attrition_predictor.dart)**
   - Método `_buildInputVector()` - construye vector de 15 floats
   - Método `_sigmoid()` - aplica función sigmoid
   - Método `_extractLogit()` - extrae valor de salida

3. **[web/onnx_loader.js](web/onnx_loader.js)**
   - Función `_buildInputVector()` - construye vector en JavaScript
   - Validación de vector length === 15
   - Tensor creado con shape [1, 15]
   - Mejorado logging con prefijo `[ONNX]`
   - Soporte para datos externos (`.data` file)

4. **[pubspec.yaml](pubspec.yaml)**
   - Se agregan assets:
     - `web/assets/workload.onnx`
     - `web/assets/workload.onnx.data`

5. **Archivos ONNX en `web/assets/`:**
   - `workload.onnx` - Estructura del modelo (15K)
   - `workload.onnx.data` - Pesos externos (1.4K)

---

## Debugging

### Si se presentan errores en consola:

1. **"Query successful" pero falla la carga**
   - El modelo está dividido en dos archivos: `.onnx` (estructura) y `.onnx.data` (pesos)
   - Se verifica que AMBOS archivos estén en `web/assets/`:
     - `web/assets/workload.onnx` (15K)
     - `web/assets/workload.onnx.data` (1.4K)
   - Se verifica que ambos estén en `pubspec.yaml` bajo `flutter.assets`

2. **"Vector debe tener 15 elementos"**
   - Se verifica que `_buildInputVector()` retorna exactamente 15 valores
   - Se revisa: 6 numeric + 6 department + 3 role = 15 

3. **"Failed to load resource: 404"**
   - El asset falta en `web/assets/`
   - El asset no está declarado en `pubspec.yaml`
   - Se ejecuta: `flutter clean && flutter pub get`

4. **"input 'input' is missing"**
   - Se verifica nombre del input en el modelo ONNX
   - Se ejecuta en consola: `console.log(ortSession.inputNames)`

5. **"Resultado: Unknown"**
   - Se revisa formato de salida ONNX
   - El modelo retorna un logit (float), no labels
   - Se revisan logs: `[ONNX] Output ...:`

---

**Última actualización:** Abril 2026
**Estado:** ✅ Verificado y funcionando
