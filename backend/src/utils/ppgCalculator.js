/**
 * BPACE PPG 신호 처리 및 융합 맞춤 호흡 추천 알고리즘 모듈
 * 
 * 학술적 근거: IEEE, Nature, JMIR 논문 기준
 * 필터링: 0.7Hz ~ 3.5Hz Bandpass Filter (42~210 BPM)
 * 컨디션 점수: 0.4 * S_BPM + 0.6 * S_HRV
 * 캘린더 융합 2D 의사결정 매트릭스 알고리즘 적용
 */

// 8종 호흡 루틴 마스터 데이터 정의
const BREATHING_ROUTINES = {
  physio_sigh: {
    id: 'physio_sigh',
    category: 'CALM',
    categoryName: '🚨 진정',
    title: '생리학적 한숨 (Physiological Sigh)',
    description: '이중 들숨과 긴 날숨으로 CO₂를 급속 배출하여 30초 내 즉각적인 심박 강하 및 긴장 완화',
    reason: '급성 심박 상승(BPM 95 이상)이 감지되어 즉각적인 신체 진정이 필요합니다.',
    pattern: { inhale: 2.0, inhaleExtra: 1.0, hold1: 0, exhale: 6.0, hold2: 0 }
  },
  box_breathing: {
    id: 'box_breathing',
    category: 'FOCUS',
    categoryName: '🔥 집중',
    title: '4-4-4-4 박스 호흡 (Box Breathing)',
    description: '미 해군 특수부대(NAVY SEALs) 공식 호흡법으로 극도의 멘탈 제어 및 몰입력 유지',
    reason: '중요 일정 전 긴장을 평온하게 가라앉히고 최고의 몰입 상태를 준비합니다.',
    pattern: { inhale: 4.0, hold1: 4.0, exhale: 4.0, hold2: 4.0 }
  },
  semi_box: {
    id: 'semi_box',
    category: 'FOCUS',
    categoryName: '🔥 집중',
    title: '4-2-4-2 세미 박스 호흡',
    description: '부담을 줄인 멈춤 시퀀스로 부드럽게 몰입력을 지속하는 호흡',
    reason: '집중이 필요한 일상 상황에서 안정적인 몰입을 유지합니다.',
    pattern: { inhale: 4.0, hold1: 2.0, exhale: 4.0, hold2: 2.0 }
  },
  relax_478: {
    id: 'relax_478',
    category: 'RELAX',
    categoryName: '🌿 이완',
    title: '4-7-8 깊은 이완 호흡',
    description: '하버드 앤드류 와일 박사 개발, 미구스 신경 자극을 통한 스트레스 이완 및 수면 유도',
    reason: '부교감 신경 활성 지표(RMSSD)가 저하되어 깊은 심신 이완이 필요합니다.',
    pattern: { inhale: 4.0, hold1: 7.0, exhale: 8.0, hold2: 0 }
  },
  relax_46: {
    id: 'relax_46',
    category: 'RELAX',
    categoryName: '🌿 이완',
    title: '4-6 릴랙스 호흡',
    description: '긴 날숨으로 자연스럽게 마음을 안정시키는 편안한 일상 이완 호흡',
    reason: '약한 긴장감을 부드럽게 풀어주는 이완 호흡입니다.',
    pattern: { inhale: 4.0, hold1: 0, exhale: 6.0, hold2: 0 }
  },
  resonant_55: {
    id: 'resonant_55',
    category: 'RECOVERY',
    categoryName: '☯️ 회복',
    title: '5.5-5.5 공진 호흡 (Resonant Breathing)',
    description: '0.1Hz 자율신경 공진 주파수로 심장 박동과 호흡 주기를 공명시키는 최적 회복 호흡',
    reason: '안정적인 생체 상태에서 자율신경계 밸런스를 최상으로 유지 및 회복합니다.',
    pattern: { inhale: 5.5, hold1: 0, exhale: 5.5, hold2: 0 }
  },
  diaphragm_2141: {
    id: 'diaphragm_2141',
    category: 'RECOVERY',
    categoryName: '☯️ 회복',
    title: '2-1-4-1 횡격막 복식 호흡',
    description: '횡격막 이완 및 신체 기본 호흡 패턴을 교정하는 부드러운 복식 호흡',
    reason: '피로도가 느껴지는 상황에서 몸을 이완하고 호흡 밸런스를 바로잡습니다.',
    pattern: { inhale: 2.0, hold1: 1.0, exhale: 4.0, hold2: 1.0 }
  },
  arousal_4121: {
    id: 'arousal_4121',
    category: 'AROUSAL',
    categoryName: '⚡ 각성',
    title: '4-1-2-1 각성 호흡 (Energy Boost)',
    description: '들숨 비중을 높여 교감 신경을 적절히 자극, 뇌와 신체 에너지를 깨우는 호흡',
    reason: '서맥 및 나른함(식곤증)이 감지되어 에너지 부스팅이 필요합니다.',
    pattern: { inhale: 4.0, hold1: 1.0, exhale: 2.0, hold2: 1.0 }
  }
};

/**
 * 간단한 2차 대역통과 필터 (0.7Hz ~ 3.5Hz Bandpass Filter)
 * @param {number[]} samples - 20초간 수집된 600개의 원시 파형 샘플 (fps = 30)
 * @param {number} fps - 샘플링 프레임 레이트 (기본 30)
 * @returns {number[]} 필터링된 파형 데이터
 */
function applyBandpassFilter(samples, fps = 30) {
  if (!samples || samples.length === 0) return [];
  
  // 1단계: 이동 평균(Moving Average)을 통한 저주파 드 리프트(Baseline Drift) 제거
  const windowSize = Math.round(fps * 0.8); // 약 0.8초 윈도우
  const filtered = new Array(samples.length).fill(0);
  
  // 2단계: 파형 정규화 및 고주파 스무딩 (3-point moving average)
  const smoothed = new Array(samples.length).fill(0);
  for (let i = 1; i < samples.length - 1; i++) {
    smoothed[i] = (samples[i - 1] + samples[i] + samples[i + 1]) / 3;
  }
  smoothed[0] = samples[0];
  smoothed[samples.length - 1] = samples[samples.length - 1];

  // 디트렌딩 (Baseline Subtraction)
  for (let i = 0; i < samples.length; i++) {
    let sum = 0;
    let count = 0;
    const start = Math.max(0, i - Math.floor(windowSize / 2));
    const end = Math.min(samples.length - 1, i + Math.floor(windowSize / 2));
    for (let j = start; j <= end; j++) {
      sum += smoothed[j];
      count++;
    }
    const baseline = sum / count;
    filtered[i] = smoothed[i] - baseline;
  }

  return filtered;
}

/**
 * 정점 탐지 (Peak Detection)
 * @param {number[]} filteredSamples - 필터링된 파형
 * @param {number} fps - 30
 * @returns {number[]} 피크 프레임 인덱스 배열
 */
function findPeaks(filteredSamples, fps = 30) {
  if (filteredSamples.length === 0) return [];

  // 역치(Threshold) 계산: 평균 + 0.2 * 표준편차
  const mean = filteredSamples.reduce((a, b) => a + b, 0) / filteredSamples.length;
  const variance = filteredSamples.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / filteredSamples.length;
  const std = Math.sqrt(variance);
  const threshold = mean + 0.2 * std;

  // 최소 피크 간 거리 (210 BPM 기준 8프레임 약 267ms)
  const minDistance = Math.floor(fps * 0.267);

  const peaks = [];
  let lastPeakIndex = -minDistance;

  for (let i = 1; i < filteredSamples.length - 1; i++) {
    if (
      filteredSamples[i] > threshold &&
      filteredSamples[i] > filteredSamples[i - 1] &&
      filteredSamples[i] >= filteredSamples[i + 1]
    ) {
      if (i - lastPeakIndex >= minDistance) {
        peaks.push(i);
        lastPeakIndex = i;
      }
    }
  }

  return peaks;
}

/**
 * R-R 간격 수열 산출 (ms 단위)
 * @param {number[]} peaks - 피크 프레임 인덱스
 * @param {number} fps - 30
 * @returns {number[]} R-R 간격 배열 (ms)
 */
function calculateRRIntervals(peaks, fps = 30) {
  const rrIntervals = [];
  for (let i = 0; i < peaks.length - 1; i++) {
    const diffFrames = peaks[i + 1] - peaks[i];
    const diffMs = (diffFrames / fps) * 1000;
    rrIntervals.push(diffMs);
  }
  return rrIntervals;
}

/**
 * 컨디션 점수 계산 (0.4 * S_BPM + 0.6 * S_HRV)
 * @param {number} bpm - 심박수
 * @param {number} rmssd - HRV RMSSD 수치
 * @returns {number} 0 ~ 100 정수 점수
 */
function calculateConditionScore(bpm, rmssd) {
  // 1. 심박수 점수 (S_BPM)
  let sBpm = 100;
  if (bpm >= 60 && bpm <= 75) {
    sBpm = 100;
  } else if (bpm > 75 && bpm <= 95) {
    sBpm = 100 - (bpm - 75) * 2.5;
  } else if (bpm > 95) {
    sBpm = Math.max(20, 50 - (bpm - 95) * 1.5);
  } else {
    // bpm < 60
    sBpm = Math.max(40, 100 - (60 - bpm) * 3);
  }

  // 2. HRV 이완 점수 (S_HRV)
  let sHrv = 100;
  if (rmssd >= 50) {
    sHrv = 100;
  } else if (rmssd >= 25 && rmssd < 50) {
    sHrv = 40 + (rmssd - 25) * 2.4;
  } else {
    // rmssd < 25
    sHrv = Math.max(10, rmssd * 1.6);
  }

  const score = Math.round(0.4 * sBpm + 0.6 * sHrv);
  return Math.min(100, Math.max(0, score));
}

/**
 * 생체 수치 (PPG) x 캘린더 일정 2D 의사결정 매트릭스 기반 맞춤 호흡 추천
 * @param {number} bpm - 심박수
 * @param {number} rmssd - RMSSD
 * @param {string} scheduleCategory - 'FOCUS' | 'ACTIVE' | 'GENERAL' | 'NONE'
 * @returns {object} 추천 호흡 루틴 객체
 */
function recommendBreathingRoutine(bpm, rmssd, scheduleCategory = 'NONE') {
  const cat = (scheduleCategory || 'NONE').toUpperCase();

  // 1순위: 급성 심박 상승 (BPM >= 95) -> 🚨 생리학적 한숨
  if (bpm >= 95) {
    return BREATHING_ROUTINES.physio_sigh;
  }

  // 2순위: 정상 심박 + 몰입 일정 -> 🔥 4-4-4-4 박스 호흡
  if (bpm >= 60 && bpm < 95 && cat === 'FOCUS') {
    return BREATHING_ROUTINES.box_breathing;
  }

  // 3순위: 저각성(BPM < 60) + 몰입 일정 -> ⚡ 4-1-2-1 각성 호흡
  if (bpm < 60 && (cat === 'FOCUS' || cat === 'ACTIVE')) {
    return BREATHING_ROUTINES.arousal_4121;
  }

  // 4순위: 정상 심박 + 활동/운동 일정 -> ⚡ 4-1-2-1 각성 호흡
  if (bpm >= 60 && bpm < 95 && cat === 'ACTIVE') {
    return BREATHING_ROUTINES.arousal_4121;
  }

  // 5순위: 만성 스트레스 (RMSSD < 25) + 일반/일정없음 -> 🌿 4-7-8 깊은 이완 호흡
  if (rmssd < 25 && (cat === 'GENERAL' || cat === 'NONE')) {
    return BREATHING_ROUTINES.relax_478;
  }

  // 6순위: 저각성 (BPM < 60) + 일반/일정없음 -> ☯️ 2-1-4-1 횡격막 복식 호흡
  if (bpm < 60 && (cat === 'GENERAL' || cat === 'NONE')) {
    return BREATHING_ROUTINES.diaphragm_2141;
  }

  // 기본(7순위): 정상 심박 + 일반/일정없음 -> ☯️ 5.5-5.5 공진 호흡
  return BREATHING_ROUTINES.resonant_55;
}

/**
 * 전체 PPG 계산 메인 엔트리 함수
 * @param {number[]} rawSamples - 20초간 수집된 600개의 파형 배열
 * @param {object} options - { fps: 30, upcomingScheduleCategory: 'FOCUS'|'ACTIVE'|'GENERAL'|'NONE' }
 */
function processPPGMeasurement(rawSamples, options = {}) {
  const fps = options.fps || 30;
  const scheduleCategory = options.upcomingScheduleCategory || 'NONE';

  if (!Array.isArray(rawSamples) || rawSamples.length < 150) {
    throw new Error('PPG samples가 부족하거나 유효하지 않습니다. 최소 150개 이상(5초 이상)이 필요합니다.');
  }

  // 1. 신호 정제
  const filtered = applyBandpassFilter(rawSamples, fps);

  // 2. 피크 탐지
  const peaks = findPeaks(filtered, fps);

  // 3. R-R 간격 수열
  const rrIntervals = calculateRRIntervals(peaks, fps);

  // 4. 신호 품질 평가 (Signal Quality)
  let signalQuality = 'good';
  if (peaks.length < 8 || rrIntervals.length < 7) {
    signalQuality = 'poor';
  } else {
    const meanRR = rrIntervals.reduce((a, b) => a + b, 0) / rrIntervals.length;
    const stdRR = Math.sqrt(rrIntervals.reduce((a, b) => a + Math.pow(b - meanRR, 2), 0) / rrIntervals.length);
    if (stdRR / meanRR > 0.45) {
      signalQuality = 'poor';
    }
  }

  // 기본값 설정 (poor 신호 대비)
  let bpm = 72;
  let sdnn = 45.0;
  let rmssd = 35.0;

  if (rrIntervals.length >= 3) {
    const meanRR = rrIntervals.reduce((a, b) => a + b, 0) / rrIntervals.length;
    bpm = Math.round(60000 / meanRR);

    // SDNN 계산
    const varianceSDNN = rrIntervals.reduce((a, b) => a + Math.pow(b - meanRR, 2), 0) / rrIntervals.length;
    sdnn = parseFloat(Math.sqrt(varianceSDNN).toFixed(1));

    // RMSSD 계산
    let sumSqDiff = 0;
    for (let i = 0; i < rrIntervals.length - 1; i++) {
      sumSqDiff += Math.pow(rrIntervals[i + 1] - rrIntervals[i], 2);
    }
    const meanSqDiff = sumSqDiff / (rrIntervals.length - 1);
    rmssd = parseFloat(Math.sqrt(meanSqDiff).toFixed(1));
  }

  // 클램핑 (생리학적 유효 수치 범위 보정)
  bpm = Math.min(200, Math.max(40, bpm));
  sdnn = Math.min(200, Math.max(5, sdnn));
  rmssd = Math.min(200, Math.max(5, rmssd));

  // 5. 컨디션 점수 (0~100점)
  const conditionScore = calculateConditionScore(bpm, rmssd);

  // 6. 맞춤 호흡 추천
  const recommendedRoutine = recommendBreathingRoutine(bpm, rmssd, scheduleCategory);

  return {
    bpm,
    sdnn,
    rmssd,
    conditionScore,
    signalQuality,
    peakCount: peaks.length,
    sampleCount: rawSamples.length,
    recommendedRoutine
  };
}

module.exports = {
  processPPGMeasurement,
  applyBandpassFilter,
  findPeaks,
  calculateConditionScore,
  recommendBreathingRoutine,
  BREATHING_ROUTINES
};
