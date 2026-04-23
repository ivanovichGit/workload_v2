let ortSession = null;

/**
 * Interceptor personalizado para cargar archivos externos (.data)
 * Soluciona el problema de "Module.MountedFiles is not available"
 */
class CustomExternalDataResolver {
  async loadFile(path) {
    console.log(`[ONNX] Loading external data from: ${path}`);
    const response = await fetch(path);
    if (!response.ok) {
      throw new Error(`Failed to fetch ${path}: ${response.status}`);
    }
    return response.arrayBuffer();
  }
}

async function loadModel() {
  if (ortSession) return ortSession;
  if (typeof ort === 'undefined') throw new Error('onnxruntime-web (ort) not loaded');
  
  const modelUrl = 'assets/workload.onnx';
  const externalDataPath = 'assets/model.onnx.data';
  
  console.log('[ONNX] Loading model from:', modelUrl);
  console.log('[ONNX] Loading external data from:', externalDataPath);
  
  try {
    // Se carga el archivo de datos externo
    console.log('[ONNX] Fetching external data file');
    const dataResponse = await fetch(externalDataPath);
    if (!dataResponse.ok) {
      throw new Error(`Failed to fetch external data: ${dataResponse.status}`);
    }
    const externalData = await dataResponse.arrayBuffer();
    console.log(`[ONNX] External data loaded (${externalData.byteLength} bytes)`);
    
    // Se crea la sesión con datos externos
    const sessionOptions = {
      executionProviders: ['wasm'],
      externalData: [
        {
          data: new Uint8Array(externalData),
          path: 'model.onnx.data'
        }
      ]
    };
    
    ortSession = await ort.InferenceSession.create(modelUrl, sessionOptions);
    console.log('[ONNX] Model loaded successfully');
    console.log('[ONNX] Input names:', ortSession.inputNames);
    console.log('[ONNX] Output names:', ortSession.outputNames);
    return ortSession;
  } catch (error) {
    console.error('[ONNX] Failed to load model with external data:', error);
    console.error('[ONNX] Error:', error.message);
    throw error;
  }
}

function _toFloat32Array(arr) {
  return new Float32Array(arr);
}

/**
 * Se construye un vector de 15 floats con one-hot encoding
 * Orden exacto:
 * [0-5]: numeric features (6 valores)
 * [6-11]: department one-hot (6 valores)
 * [12-14]: role_level one-hot (3 valores)
 */
function _buildInputVector(inputMap) {
  const departments = ['Engineering', 'Finance', 'HR', 'Marketing', 'Operations', 'Sales'];
  const roleLevels = ['Junior', 'Mid', 'Senior'];
  
  const vector = [];
  
  // Se agregan valores numéricos (posiciones 0-5)
  vector.push(Number(inputMap['monthly_salary']) || 0);
  vector.push(Number(inputMap['avg_weekly_hours']) || 0);
  vector.push(Number(inputMap['projects_handled']) || 0);
  vector.push(Number(inputMap['performance_rating']) || 0);
  vector.push(Number(inputMap['absences_days']) || 0);
  vector.push(Number(inputMap['job_satisfaction']) || 0);
  
  // Se agrega one-hot encoding para departamento (posiciones 6-11)
  const department = String(inputMap['department'] || '');
  for (const dept of departments) {
    vector.push(department === dept ? 1.0 : 0.0);
  }
  
  // Se agrega one-hot encoding para nivel de rol (posiciones 12-14)
  const roleLevel = String(inputMap['role_level'] || '');
  for (const role of roleLevels) {
    vector.push(roleLevel === role ? 1.0 : 0.0);
  }
  
  console.log('Input vector (15 floats):', vector);
  return vector;
}

async function runOnnxInference(inputMap) {
  console.log('[ONNX] Starting inference');
  
  const session = await loadModel();
  
  // Se detecta si el vector ya fue construido
  let vector;
  if (Array.isArray(inputMap['input_vector']) && inputMap['input_vector'].length === 15) {
    // Se usa el vector directamente
    vector = inputMap['input_vector'];
    console.log('[ONNX] Using pre-built input vector (15 floats)');
  } else {
    // Se construye el vector desde los campos individuales
    console.log('[ONNX] Building input vector from fields');
    vector = _buildInputVector(inputMap);
  }
  
  // Se valida que el vector tenga exactamente 15 elementos
  if (vector.length !== 15) {
    const errMsg = `Input vector must have exactly 15 elements, got ${vector.length}`;
    console.error('[ONNX] Validation error:', errMsg);
    throw new Error(errMsg);
  }
  
  console.log('[ONNX] Vector validated (15 elements)');
  
  // Se crea el tensor de entrada
  const feeds = {};
  const inputTensor = new ort.Tensor('float32', _toFloat32Array(vector), [1, 15]);
  
  // Se detecta el nombre del input desde la sesión
  const inputName = session.inputNames && session.inputNames.length > 0
    ? session.inputNames[0]
    : 'input';
  
  feeds[inputName] = inputTensor;
  
  console.log(`[ONNX] Running inference with shape [1, 15] on input: "${inputName}"`);
  console.log('[ONNX] Vector:', vector);
  
  let results;
  try {
    results = await session.run(feeds);
    console.log('[ONNX] Inference completed');
  } catch (err) {
    console.error('[ONNX] Inference error:', err);
    throw err;
  }
  
  // Se extrae la salida del modelo
  const out = {};
  for (const k of Object.keys(results)) {
    const val = results[k].data;
    out[k] = Array.from(val);
    console.log(`[ONNX] Output "${k}":`, Array.from(val));
  }
  
  return out;
}

window.runOnnxInference = runOnnxInference;
