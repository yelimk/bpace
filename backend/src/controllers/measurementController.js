const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { processPPGMeasurement } = require('../utils/ppgCalculator');

/**
 * POST /api/measurements
 * 카메라 PPG 생체 파형 수집 및 결과 연산 API
 * Body: {
 *   userId?: string,
 *   samples: number[], // 20초간 600개 파형 샘플
 *   fps?: number, // 기본 30
 *   upcomingScheduleCategory?: 'FOCUS' | 'ACTIVE' | 'GENERAL' | 'NONE'
 * }
 */
async function createMeasurement(req, res) {
  try {
    const { userId, samples, fps = 30, upcomingScheduleCategory = 'NONE' } = req.body;

    // 1. 유효성 검사
    if (!samples || !Array.isArray(samples) || samples.length < 150) {
      return res.status(400).json({
        status: 'error',
        message: '유효하지 않은 파형 데이터입니다. 최소 150개 이상(5초 이상)의 samples 배열이 필요합니다.'
      });
    }

    // 2. PPG 정밀 신호 처리 & 2D 캘린더 융합 알고리즘 수행
    const result = processPPGMeasurement(samples, {
      fps: Number(fps),
      upcomingScheduleCategory
    });

    // 3. DB 보존 (회원/비회원 구분)
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
    } catch (dbError) {
      console.warn('Prisma DB 저장 경고 (비회원/테스트 모드 처리):', dbError.message);
    }

    // 4. 응답 구성
    return res.status(201).json({
      status: 'success',
      data: {
        id: savedMeasurement ? savedMeasurement.id : 'temp-' + Date.now(),
        userId: userId || null,
        bpm: result.bpm,
        rmssd: result.rmssd,
        sdnn: result.sdnn,
        conditionScore: result.conditionScore,
        signalQuality: result.signalQuality,
        samplesCount: result.sampleCount,
        measuredAt: savedMeasurement ? savedMeasurement.measuredAt : new Date().toISOString(),
        recommendedRoutine: result.recommendedRoutine
      }
    });
  } catch (error) {
    console.error('PPG Measurement API 오류:', error);
    return res.status(500).json({
      status: 'error',
      message: 'PPG 신호 연산 중 오류가 발생했습니다.',
      detail: error.message
    });
  }
}

/**
 * GET /api/measurements
 * 최근 측정 내역 조회 (회원별 또는 최근 10개)
 */
async function getMeasurements(req, res) {
  try {
    const { userId, limit = 10 } = req.query;

    const where = userId ? { userId: String(userId) } : {};
    const measurements = await prisma.measurement.findMany({
      where,
      orderBy: { measuredAt: 'desc' },
      take: Number(limit)
    });

    return res.json({
      status: 'success',
      count: measurements.length,
      data: measurements
    });
  } catch (error) {
    console.error('Measurement 조회 오류:', error);
    return res.status(500).json({
      status: 'error',
      message: '측정 기록 조회 중 오류가 발생했습니다.'
    });
  }
}

module.exports = {
  createMeasurement,
  getMeasurements
};
