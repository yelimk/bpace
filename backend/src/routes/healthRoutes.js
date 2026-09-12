/**
 * BPACE 헬스 체크 및 시스템 상태 모니터링 라우트
 */

const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { sendSuccess, sendError } = require('../utils/responseHelper');

/**
 * GET /api/health
 * 서버 헬스 체크 및 DB 핑 연결 상태 모니터링
 */
router.get('/', async (req, res) => {
  try {
    let dbStatus = 'ok';
    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch (dbErr) {
      console.error('[Health Check DB Ping Error]:', dbErr.message);
      dbStatus = 'error';
    }

    return sendSuccess(res, {
      status: dbStatus === 'ok' ? 'ok' : 'degraded',
      service: 'BPACE Backend API',
      version: '1.0.0',
      uptimeSeconds: Math.floor(process.uptime()),
      dbConnection: dbStatus,
      timestamp: new Date().toISOString(),
      env: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    console.error('[Health Check Error]:', error);
    return sendError(res, 'SERVER_ERROR', '서버 헬스 체크 중 오류가 발생했습니다.', 500);
  }
});

/**
 * GET /api/health/version
 * API 버전 정보 반환
 */
router.get('/version', (req, res) => {
  return sendSuccess(res, {
    name: 'BPACE Backend Core API',
    version: '1.0.0',
    description: 'Mindfulness & Autonomous Nervous System Biometric Analytics Platform',
    license: 'MIT',
    author: 'BPACE Team'
  });
});

module.exports = router;
