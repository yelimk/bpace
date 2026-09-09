const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { processPPGMeasurement } = require('../utils/ppgCalculator');
const { sendSuccess, sendError } = require('../utils/responseHelper');

/**
 * POST /api/measurements
 * 회원 생체 파형 수집 및 결과 연산 API (DB 저장)
 */
async function createMeasurement(req, res) {
  try {
    const { userId, samples, fps = 30, durationSec = 20, upcomingScheduleCategory = 'NONE' } = req.body;

    // 1. 유효성 검사
    if (!samples || !Array.isArray(samples) || samples.length < 150) {
      return sendError(
        res,
        'INVALID_INPUT',
        '측정된 신호가 부족하거나 유효하지 않습니다. 손가락을 카메라에 대고 다시 측정해 주세요.',
        400
      );
    }

    // 2. PPG 정밀 신호 처리 및 2D 캘린더 융합 알고리즘 연산
    const result = processPPGMeasurement(samples, {
      fps: Number(fps),
      upcomingScheduleCategory
    });

    if (result.signalQuality === 'poor') {
      // 신호 불량 시 프론트엔드가 감지할 수 있도록 에러 파라미터 반환 가능
      console.warn('PPG 신호 품질 불량 감지: good 상태 보정 또는 재측정 권장');
    }

    // 3. DB 저장
    let savedMeasurement = null;
    try {
      savedMeasurement = await prisma.measurement.create({
        data: {
          userId: userId || null,
          bpm: result.bpm,
          hrvRmssd: result.rmssd,
          hrvSdnn: result.sdnn,
          conditionScore: result.conditionScore,
          signalQuality: result.signalQuality,
          samplesCount: samples.length
        }
      });
    } catch (dbErr) {
      console.warn('Prisma DB 저장 경고 (비회원/게스트 모드 처리):', dbErr.message);
    }

    // 4. 프론트엔드 규격 (success: true, data: { ... }) 전송
    return sendSuccess(res, {
      id: savedMeasurement ? savedMeasurement.id : 'temp-' + Date.now(),
      userId: userId || null,
      bpm: result.bpm,
      rmssd: result.rmssd,
      sdnn: result.sdnn,
      conditionScore: result.conditionScore,
      signalQuality: result.signalQuality,
      samplesCount: result.sampleCount,
      measuredAt: savedMeasurement ? savedMeasurement.measuredAt.toISOString() : new Date().toISOString(),
      recommendedRoutine: result.recommendedRoutine
    }, 201);
  } catch (error) {
    console.error('PPG Measurement API 오류:', error);
    return sendError(res, 'SERVER_ERROR', 'PPG 신호 연산 중 오류가 발생했습니다: ' + error.message, 500);
  }
}

/**
 * POST /api/measurements/analyze
 * 게스트/비회원 파형 실시간 분석 API (DB 저장 없이 분석만 반환)
 */
async function analyzeMeasurement(req, res) {
  try {
    const { samples, fps = 30, upcomingScheduleCategory = 'NONE' } = req.body;

    if (!samples || !Array.isArray(samples) || samples.length < 150) {
      return sendError(
        res,
        'INVALID_INPUT',
        '측정된 신호가 부족합니다. 손가락을 카메라 플래시에 밀착 후 다시 측정해 주세요.',
        400
      );
    }

    const result = processPPGMeasurement(samples, {
      fps: Number(fps),
      upcomingScheduleCategory
    });

    return sendSuccess(res, {
      id: 'guest-' + Date.now(),
      bpm: result.bpm,
      rmssd: result.rmssd,
      sdnn: result.sdnn,
      conditionScore: result.conditionScore,
      signalQuality: result.signalQuality,
      samplesCount: result.sampleCount,
      measuredAt: new Date().toISOString(),
      recommendedRoutine: result.recommendedRoutine
    });
  } catch (error) {
    console.error('PPG Guest Analyze API 오류:', error);
    return sendError(res, 'SERVER_ERROR', '파형 분석 중 오류가 발생했습니다.', 500);
  }
}

/**
 * GET /api/measurements
 * 최근 측정 내역 조회
 */
async function getMeasurements(req, res) {
  try {
    const { userId, limit = 20 } = req.query;
    const where = userId ? { userId: String(userId) } : {};

    const measurements = await prisma.measurement.findMany({
      where,
      orderBy: { measuredAt: 'desc' },
      take: Number(limit)
    });

    return sendSuccess(res, measurements);
  } catch (error) {
    console.error('Measurement 조회 오류:', error);
    return sendError(res, 'SERVER_ERROR', '측정 기록 조회 중 오류가 발생했습니다.', 500);
  }
}

module.exports = {
  createMeasurement,
  analyzeMeasurement,
  getMeasurements
};
