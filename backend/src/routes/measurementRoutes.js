const express = require('express');
const router = express.Router();
const measurementController = require('../controllers/measurementController');

// POST /api/measurements - PPG 생체 파형 수집 및 결과 연산 API
router.post('/', measurementController.createMeasurement);

// GET /api/measurements - 최근 측정 기록 조회 API
router.get('/', measurementController.getMeasurements);

module.exports = router;
