const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { sendError } = require('../utils/responseHelper');

const JWT_SECRET = process.env.JWT_SECRET || 'bpace_jwt_secret_key_2026';

/**
 * JWT 인증 미들웨어
 * Authorization: Bearer <token>
 */
async function authenticateToken(req, res, next) {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

    if (!token) {
      return sendError(res, 'UNAUTHORIZED', '로그인이 필요합니다. 인증 토큰이 누락되었습니다.', 401);
    }

    // 토큰 검증
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return sendError(res, 'UNAUTHORIZED', '인증 토큰이 유효하지 않거나 만료되었습니다. 다시 로그인해 주세요.', 401);
    }

    // DB 사용자 조회
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId }
    });

    if (!user) {
      return sendError(res, 'UNAUTHORIZED', '존재하지 않는 사용자 계정입니다.', 401);
    }

    // req.user에 사용자 정보 바인딩
    req.user = {
      id: user.id,
      email: user.email,
      nickname: user.name,
      authProvider: user.authProvider,
      createdAt: user.createdAt
    };

    next();
  } catch (error) {
    console.error('authMiddleware 오류:', error);
    return sendError(res, 'SERVER_ERROR', '인증 처리 중 오류가 발생했습니다.', 500);
  }
}

/**
 * 선택적 JWT 인증 미들웨어 (게스트 및 회원 모두 지원)
 * 토큰이 있으면 유저 검증, 없으면 req.user = null 로 진행
 */
async function optionalAuthMiddleware(req, res, next) {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

    if (!token) {
      req.user = null;
      return next();
    }

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId }
      });
      if (user) {
        req.user = {
          id: user.id,
          email: user.email,
          nickname: user.name,
          authProvider: user.authProvider,
          createdAt: user.createdAt
        };
      } else {
        req.user = null;
      }
    } catch (_) {
      req.user = null;
    }
    next();
  } catch (error) {
    req.user = null;
    next();
  }
}

module.exports = {
  authenticateToken,
  optionalAuthMiddleware,
  JWT_SECRET
};
