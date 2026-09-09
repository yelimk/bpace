const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { sendSuccess, sendError } = require('../utils/responseHelper');

/**
 * POST /api/schedules
 * 일정 신규 등록
 */
async function createSchedule(req, res) {
  try {
    const { title, startTime, endTime, category } = req.body;

    if (!title || typeof title !== 'string' || !title.trim()) {
      return sendError(res, 'INVALID_INPUT', '일정 제목을 입력해 주세요.', 400);
    }

    if (!startTime) {
      return sendError(res, 'INVALID_INPUT', '일정 시작 시간을 입력해 주세요.', 400);
    }

    const startDt = new Date(startTime);
    if (isNaN(startDt.getTime())) {
      return sendError(res, 'INVALID_INPUT', '유효한 시작 시간 날짜 형식이 아닙니다.', 400);
    }

    const endDt = endTime ? new Date(endTime) : new Date(startDt.getTime() + 60 * 60 * 1000); // default 1 hr

    // 유저가 로그인한 경우 유저 ID 연결, 아닌 경우 게스트 전용 시스템 ID 사용
    let userId = req.user ? req.user.id : null;

    if (!userId) {
      // 게스트 모드 기본 시스템 유저 확보
      let guestUser = await prisma.user.findFirst({
        where: { email: 'guest@bpace.com' }
      });
      if (!guestUser) {
        guestUser = await prisma.user.create({
          data: {
            email: 'guest@bpace.com',
            name: '게스트 사용자',
            authProvider: 'guest'
          }
        });
      }
      userId = guestUser.id;
    }

    const schedule = await prisma.schedule.create({
      data: {
        userId,
        title: title.trim(),
        startTime: startDt,
        endTime: endDt,
        syncedToGoogle: false
      }
    });

    return sendSuccess(res, schedule, 201);
  } catch (error) {
    console.error('일정 생성 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '일정 생성 중 오류가 발생했습니다.', 500);
  }
}

/**
 * GET /api/schedules
 * 캘린더 일정 목록 조회 (날짜 쿼리 및 다가오는 30분 이내 일정 조회)
 */
async function getSchedules(req, res) {
  try {
    const { year, month, date, upcomingOnly } = req.query;
    let userId = req.user ? req.user.id : null;

    if (!userId) {
      const guestUser = await prisma.user.findFirst({
        where: { email: 'guest@bpace.com' }
      });
      if (guestUser) userId = guestUser.id;
    }

    const whereCondition = userId ? { userId } : {};

    // 1. 다가오는 30분 이내 일정만 조회하는 경우 (PPG 2D 추천 엔진 연동)
    if (upcomingOnly === 'true') {
      const now = new Date();
      const in30Min = new Date(now.getTime() + 30 * 60 * 1000);

      const upcomingSchedules = await prisma.schedule.findMany({
        where: {
          ...whereCondition,
          startTime: {
            gte: new Date(now.getTime() - 5 * 60 * 1000), // 5분 그레이스 타임
            lte: in30Min
          }
        },
        orderBy: { startTime: 'asc' }
      });

      return sendSuccess(res, upcomingSchedules);
    }

    // 2. 일반 캘린더 날짜/월별 조회
    const allSchedules = await prisma.schedule.findMany({
      where: whereCondition,
      orderBy: { startTime: 'asc' }
    });

    return sendSuccess(res, allSchedules);
  } catch (error) {
    console.error('일정 목록 조회 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '일정 목록 조회 중 오류가 발생했습니다.', 500);
  }
}

/**
 * PATCH /api/schedules/:id/complete
 * 일정 완료 처리 / 체크 토글
 */
async function completeSchedule(req, res) {
  try {
    const { id } = req.params;
    const { completed } = req.body;

    const schedule = await prisma.schedule.findUnique({
      where: { id }
    });

    if (!schedule) {
      return sendError(res, 'NOT_FOUND', '존재하지 않는 일정입니다.', 404);
    }

    const updated = await prisma.schedule.update({
      where: { id },
      data: {
        syncedToGoogle: completed !== undefined ? Boolean(completed) : !schedule.syncedToGoogle
      }
    });

    return sendSuccess(res, updated);
  } catch (error) {
    console.error('일정 완료 체크 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '일정 완료 상태 변경 중 오류가 발생했습니다.', 500);
  }
}

/**
 * PUT /api/schedules/:id
 * 일정 수정
 */
async function updateSchedule(req, res) {
  try {
    const { id } = req.params;
    const { title, startTime, endTime } = req.body;

    const schedule = await prisma.schedule.findUnique({
      where: { id }
    });

    if (!schedule) {
      return sendError(res, 'NOT_FOUND', '존재하지 않는 일정입니다.', 404);
    }

    const updateData = {};
    if (title && typeof title === 'string') updateData.title = title.trim();
    if (startTime) updateData.startTime = new Date(startTime);
    if (endTime) updateData.endTime = new Date(endTime);

    const updated = await prisma.schedule.update({
      where: { id },
      data: updateData
    });

    return sendSuccess(res, updated);
  } catch (error) {
    console.error('일정 수정 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '일정 수정 중 오류가 발생했습니다.', 500);
  }
}

/**
 * DELETE /api/schedules/:id
 * 일정 삭제
 */
async function deleteSchedule(req, res) {
  try {
    const { id } = req.params;

    const schedule = await prisma.schedule.findUnique({
      where: { id }
    });

    if (!schedule) {
      return sendError(res, 'NOT_FOUND', '존재하지 않는 일정입니다.', 404);
    }

    await prisma.schedule.delete({
      where: { id }
    });

    return sendSuccess(res, null);
  } catch (error) {
    console.error('일정 삭제 중 오류:', error);
    return sendError(res, 'SERVER_ERROR', '일정 삭제 중 오류가 발생했습니다.', 500);
  }
}

/**
 * POST /api/schedules/sync
 * 구글 캘린더 동기화 스텁
 */
async function syncGoogleCalendar(req, res) {
  return sendSuccess(res, {
    syncedCount: 0,
    message: 'Google Calendar OAuth sync stub ready'
  });
}

module.exports = {
  createSchedule,
  getSchedules,
  completeSchedule,
  updateSchedule,
  deleteSchedule,
  syncGoogleCalendar
};
