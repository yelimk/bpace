const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/scheduleController');
const { optionalAuthMiddleware } = require('../middlewares/authMiddleware');

// POST /api/schedules - 일정 등록
router.post('/', optionalAuthMiddleware, scheduleController.createSchedule);

// GET /api/schedules - 일정 목록 및 다가오는 30분 이내 일정 조회
router.get('/', optionalAuthMiddleware, scheduleController.getSchedules);

// PATCH /api/schedules/:id/complete - 일정 완료 체크
router.patch('/:id/complete', optionalAuthMiddleware, scheduleController.completeSchedule);

// PUT /api/schedules/:id - 일정 수정
router.put('/:id', optionalAuthMiddleware, scheduleController.updateSchedule);

// DELETE /api/schedules/:id - 일정 삭제
router.delete('/:id', optionalAuthMiddleware, scheduleController.deleteSchedule);

// POST /api/schedules/sync - 구글 캘린더 동기화 스텁
router.post('/sync', optionalAuthMiddleware, scheduleController.syncGoogleCalendar);

module.exports = router;
