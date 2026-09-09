const express = require('express');
const router = express.Router();
const statisticsController = require('../controllers/statisticsController');
const { optionalAuthMiddleware } = require('../middlewares/authMiddleware');

// GET /api/statistics/summary - 마이페이지 및 요약 통계 조회
router.get('/summary', optionalAuthMiddleware, statisticsController.getSummary);

// GET /api/statistics/daily - 요일별 수행 분포 조회
router.get('/daily', optionalAuthMiddleware, statisticsController.getDailyDistribution);

module.exports = router;
