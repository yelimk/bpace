const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { sendSuccess, sendError } = require('./utils/responseHelper');

const app = express();

// Express Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes Import
const authRoutes = require('./routes/authRoutes');
const measurementRoutes = require('./routes/measurementRoutes');
const breathingLogRoutes = require('./routes/breathingLogRoutes');
const statisticsRoutes = require('./routes/statisticsRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');
const reportRoutes = require('./routes/reportRoutes');
const healthRoutes = require('./routes/healthRoutes');

// API Routes Mounting
app.use('/api/health', healthRoutes);

// API Routes Mounting
app.use('/api/auth', authRoutes);
app.use('/api/measurements', measurementRoutes);
app.use('/api/breathing-logs', breathingLogRoutes);
app.use('/api/statistics', statisticsRoutes);
app.use('/api/schedules', scheduleRoutes);
app.use('/api/reports', reportRoutes);

// 404 Route Handler
app.use((req, res) => {
  return sendError(res, 'NOT_FOUND', '요청하신 API 엔드포인트를 찾을 수 없습니다.', 404);
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled Error:', err);
  return sendError(
    res,
    'SERVER_ERROR',
    process.env.NODE_ENV === 'development' ? err.message : '서버 내부 오류가 발생했습니다.',
    500
  );
});

module.exports = app;
