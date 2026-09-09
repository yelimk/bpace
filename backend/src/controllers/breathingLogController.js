const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { sendSuccess, sendError } = require('../utils/responseHelper');

/**
 * POST /api/breathing-logs
 * 호흡 세션 완료 기록 저장
 */
async function createBreathingLog(req, res) {
  try {
    const { category, routineName, durationSeconds, completionRate, userNotes } = req.body;

    if (!routineName || typeof routineName !== 'string') {
      return sendError(res, 'INVALID_INPUT', '호흡 루틴 이름을 입력해 주세요.', 400);
    }

    const duration = parseInt(durationSeconds, 10);
    if (isNaN(duration) || duration <= 0) {
      return sendError(res, 'INVALID_INPUT', '수행 시간(초)을 올바르게 입력해 주세요.', 400);
    }

    const logCategory = (category && typeof category === 'string') ? category.trim() : '이완';

    const userId = req.user ? req.user.id : null;

    const log = await prisma.breathingLog.create({
      data: {
        userId,
        category: logCategory,
        routineName: routineName.trim(),
        durationSeconds: duration,
        completionRate: typeof completionRate === 'number' ? completionRate : 100.0,
        userNotes: userNotes ? String(userNotes).trim() : null
      }
    });

    return sendSuccess(res, log, 201);
  } catch (error) {
    console.error('호흡 기록 저장 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '호흡 기록 저장 중 오류가 발생했습니다.', 500);
  }
}

/**
 * GET /api/breathing-logs
 * 호흡 세션 완료 기록 목록 조회 (가장 최근순 정렬)
 */
async function getBreathingLogs(req, res) {
  try {
    const userId = req.user ? req.user.id : null;

    const whereCondition = userId ? { userId } : {};

    const logs = await prisma.breathingLog.findMany({
      where: whereCondition,
      orderBy: { completedAt: 'desc' }
    });

    return sendSuccess(res, logs);
  } catch (error) {
    console.error('호흡 기록 목록 조회 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '호흡 기록 목록 조회 중 오류가 발생했습니다.', 500);
  }
}

module.exports = {
  createBreathingLog,
  getBreathingLogs
};
