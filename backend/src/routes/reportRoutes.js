/**
 * BPACE AI 리포트 및 피드백 라우트 (`/api/reports`)
 */

const express = require('express');
const router = express.Router();
const { optionalAuthMiddleware } = require('../middlewares/authMiddleware');
const {
  getLatestReport,
  generateRealtimeReport,
  generateBreathingFeedback
} = require('../controllers/reportController');

// 1. GET /api/reports/latest 및 GET /api/reports/weekly (최근 DB 저장본 조회)
router.get('/latest', optionalAuthMiddleware, getLatestReport);
router.get('/weekly', optionalAuthMiddleware, getLatestReport);

// 2. POST /api/reports/analyze 및 POST /api/reports/weekly (실시간 AI 분석 생성)
router.post('/analyze', optionalAuthMiddleware, generateRealtimeReport);
router.post('/weekly', optionalAuthMiddleware, generateRealtimeReport);

// 3. POST /api/reports/feedback (호흡 완주 피드백 + 오늘의 한마디)
router.post('/feedback', optionalAuthMiddleware, generateBreathingFeedback);

module.exports = router;
