const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middlewares/authMiddleware');

// POST /api/auth/signup - 회원가입
router.post('/signup', authController.signup);

// POST /api/auth/login - 이메일 로그인
router.post('/login', authController.login);

// POST /api/auth/social - 구글 소셜 로그인
router.post('/social', authController.socialLogin);

// POST /api/auth/logout - 로그아웃
router.post('/logout', authController.logout);

// DELETE /api/auth/withdraw - 회원 탈퇴 (인증 필요)
router.delete('/withdraw', authenticateToken, authController.withdraw);

// GET /api/auth/me - 내 프로필 조회 (인증 필요)
router.get('/me', authenticateToken, authController.getMe);

// POST /api/auth/dev-reset-users - 개발용 계정 초기화 API
router.post('/dev-reset-users', authController.devResetUsers);

// GET /api/auth/dev-list-users - 개발용 계정 목록 조회 API
router.get('/dev-list-users', authController.devListUsers);

module.exports = router;


