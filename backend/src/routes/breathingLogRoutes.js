const express = require('express');
const router = express.Router();
const breathingLogController = require('../controllers/breathingLogController');
const { optionalAuthMiddleware } = require('../middlewares/authMiddleware');

// POST /api/breathing-logs - 호흡 완료 기록 저장
router.post('/', optionalAuthMiddleware, breathingLogController.createBreathingLog);

// GET /api/breathing-logs - 호흡 완료 기록 목록 조회
router.get('/', optionalAuthMiddleware, breathingLogController.getBreathingLogs);

module.exports = router;
