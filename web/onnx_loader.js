let ortSession = null;

async function loadModel() {
  if (ortSession) return ortSession;
  if (typeof ort === 'undefined') throw new Error('onnxruntime-web (ort) not loaded');
  const modelUrl = '/assets/workload.onnx';
  ortSession = await ort.InferenceSession.create(modelUrl, { executionProviders: ['wasm'] });
  console.log('ONNX model loaded:', modelUrl);
  return ortSession;
}

function _toFloat32Array(arr) {
  return new Float32Array(arr);
}

async function runOnnxInference(inputMap) {
  const session = await loadModel();

  const feeds = {};
  const multiInputs = session.inputNames && session.inputNames.length > 1;

  if (multiInputs) {
    // Modelo con múltiples inputs nombrados
    for (const inputName of session.inputNames) {
      const v = inputMap[inputName];

      let expectString = false;
      try {
        const meta = session.inputMetadata && session.inputMetadata[inputName];
        if (meta) {
          const s = JSON.stringify(meta).toLowerCase();
          if (s.includes('string')) expectString = true;
        }
      } catch (e) { /* ignore */ }

      if (v === undefined) {
        throw new Error(`input '${inputName}' is missing in 'feeds'.`);
      }

      if (expectString || typeof v === 'string') {
        let arr;
        if (v === null) arr = [''];
        else if (Array.isArray(v)) arr = v.map(x => String(x));
        else arr = [String(v)];
        feeds[inputName] = new ort.Tensor('string', arr, [1, arr.length]);
      } else {
        let arr;
        if (v === null) arr = [NaN];
        else if (typeof v === 'boolean') arr = [v ? 1.0 : 0.0];
        else if (typeof v === 'number') arr = [v];
        else if (Array.isArray(v)) arr = v.map(x => Number(x));
        else {
          let h = 0;
          for (let i = 0; i < v.length; i++) h = (h * 31 + v.charCodeAt(i)) & 0xffffffff;
          arr = [(h % 1000) / 1000.0];
        }
        feeds[inputName] = new ort.Tensor('float32', _toFloat32Array(arr), [1, arr.length]);
      }
    }
  } else {
    // Modelo con un solo tensor de entrada: aplanar todo en el orden correcto
    const keys = [
      'department', 'role_level', 'monthly_salary', 'avg_weekly_hours',
      'projects_handled', 'performance_rating', 'absences_days', 'job_satisfaction'
    ];
    const flat = [];
    for (const k of keys) {
      const v = inputMap[k];
      if (v === null || v === undefined) flat.push(NaN);
      else if (typeof v === 'boolean') flat.push(v ? 1.0 : 0.0);
      else if (typeof v === 'number') flat.push(v);
      else if (Array.isArray(v)) { for (const vv of v) flat.push(Number(vv)); }
      else {
        let h = 0;
        for (let i = 0; i < v.length; i++) h = (h * 31 + v.charCodeAt(i)) & 0xffffffff;
        flat.push(h % 1000 / 1000.0);
      }
    }
    const inputTensor = new ort.Tensor('float32', _toFloat32Array(flat), [1, flat.length]);
    const inputName = session.inputNames && session.inputNames.length
      ? session.inputNames[0]
      : Object.keys(session._inputNames || {})[0];
    feeds[inputName] = inputTensor;
  }

  let results;
  try {
    results = await session.run(feeds);
  } catch (err) {
    console.error('OrtRun failed:', err);
    throw err;
  }

  const out = {};
  for (const k of Object.keys(results)) {
    const val = results[k].data;
    out[k] = Array.from(val);
  }
  return out;
}

window.runOnnxInference = runOnnxInference;
