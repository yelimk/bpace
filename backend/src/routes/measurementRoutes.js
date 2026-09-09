const express = require('express');
const router = express.Router();
const measurementController = require('../controllers/measurementController');

// POST /api/measurements - 회원 생체 파형 수집 및 결과 연산 API (DB 저장)
router.post('/', measurementController.createMeasurement);

// POST /api/measurements/analyze - 비회원/게스트 생체 파형 분석 API (DB 저장 없음)
router.post('/analyze', measurementController.analyzeMeasurement);

// GET /api/measurements - 최근 측정 기록 조회 API
router.get('/', measurementController.getMeasurements);

module.exports = router;
