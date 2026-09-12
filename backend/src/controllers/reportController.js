/**
 * BPACE AI 리포트 및 피드백 컨트롤러
 * 
 * - POST /api/reports/analyze (또는 /weekly): 측정 시마다 실시간 100% Gemini AI 생체 분석
 * - POST /api/reports/feedback: 호흡 완료 시마다 실시간 AI 피드백 + 오늘의 한마디
 * - GET /api/reports/latest: 최근 생성된 AI 리포트 DB 조회
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { sendSuccess, sendError } = require('../utils/responseHelper');
const { buildSlotAPrompt, buildSlotBPrompt } = require('../services/reportPrompt');
const { generateAiContent } = require('../services/geminiService');

/**
 * 이번 주 월요일 날짜 문자열 반환 (YYYY-MM-DD)
 */
function getWeekStartDate(d = new Date()) {
  const date = new Date(d);
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(date.setDate(diff));
  return monday.toISOString().split('T')[0];
}

/**
 * 초 단위 시간을 "M분 S초" 문자열로 변환
 */
function formatDuration(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}분 ${s}초`;
}

/**
 * GET /api/reports/latest
 * 최근 생성된 AI 리포트 DB 저장본 조회
 */
async function getLatestReport(req, res) {
  try {
    const userId = req.user?.id || null;

    const report = await prisma.aiReport.findFirst({
      where: { userId: userId },
      orderBy: { createdAt: 'desc' }
    });

    if (!report) {
      return sendSuccess(res, {
        hasReport: false,
        message: "생성된 AI 주간 리포트가 없습니다. 측정 완료 후 실시간 리포트를 생성해보세요."
      });
    }

    return sendSuccess(res, {
      hasReport: true,
      report: report
    });
  } catch (error) {
    console.error('[getLatestReport Error]:', error);
    return sendError(res, 'INTERNAL_SERVER_ERROR', 'AI 리포트 조회 중 오류가 발생했습니다.', 500);
  }
}

/**
 * POST /api/reports/analyze (및 /weekly)
 * 실시간 AI 생체 데이터 분석 및 주간 리포트 생성
 */
async function generateRealtimeReport(req, res) {
  try {
    const userId = req.user?.id || null;
    const weekStart = getWeekStartDate();

    let { avgBpm, maxBpm, minBpm, hrvSdnnMs, conditionScore } = req.body || {};

    // 바디 데이터가 없으면 최근 측정 데이터에서 자동 계산
    if (!avgBpm) {
      const recentMeasurements = await prisma.measurement.findMany({
        where: { userId: userId },
        take: 10,
        orderBy: { measuredAt: 'desc' }
      });

      if (recentMeasurements.length === 0) {
        // 기본 샘플 데이터 설정
        avgBpm = 82;
        maxBpm = 94;
        minBpm = 68;
        hrvSdnnMs = 45;
        conditionScore = 80;
      } else {
        const bpms = recentMeasurements.map(m => m.bpm);
        avgBpm = Math.round(bpms.reduce((a, b) => a + b, 0) / bpms.length);
        maxBpm = Math.max(...bpms);
        minBpm = Math.min(...bpms);
        hrvSdnnMs = Math.round(recentMeasurements.reduce((a, m) => a + (m.hrvSdnn || 35), 0) / recentMeasurements.length);
        conditionScore = Math.round(recentMeasurements.reduce((a, m) => a + (m.conditionScore || 80), 0) / recentMeasurements.length);
      }
    }

    // 1. 프롬프트 생성
    const promptData = { avgBpm, maxBpm, minBpm, hrvSdnnMs, conditionScore };
    const promptText = buildSlotAPrompt(promptData);

    // 2. 실시간 Gemini AI 호출 (실패 시 에러 처리)
    let aiResult;
    try {
      aiResult = await generateAiContent(promptText);
    } catch (aiError) {
      return sendError(
        res,
        aiError.code || 'AI_SERVICE_UNAVAILABLE',
        aiError.userMessage || '현재 AI 분석을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.',
        503
      );
    }

    // 3. DB에 리포트 저장
    const newReport = await prisma.aiReport.create({
      data: {
        userId: userId,
        weekStartDate: weekStart,
        headline: aiResult.headline || "심박수가 높아지는 순간, 리추얼이 도움이 될 수 있어요",
        avgBpmAnalysis: aiResult.avgBpmAnalysis || `오늘의 평균 심박수는 ${avgBpm} BPM으로 안정적이에요.`,
        maxBpmAnalysis: aiResult.maxBpmAnalysis || `최고 심박수는 ${maxBpm} BPM까지 상승했어요.`,
        minBpmAnalysis: aiResult.minBpmAnalysis || `최저 심박수는 ${minBpm} BPM입니다.`,
        overallGuide: aiResult.overallGuide || "전반적인 컨디션 관리를 위한 호흡 리추얼을 추천드려요."
      }
    });

    return sendSuccess(res, {
      report: newReport
    }, 201);
  } catch (error) {
    console.error('[generateRealtimeReport Error]:', error);
    return sendError(res, 'INTERNAL_SERVER_ERROR', 'AI 분석 리포트 생성 중 오류가 발생했습니다.', 500);
  }
}

/**
 * POST /api/reports/feedback
 * 슬롯 B: 호흡 완주 실시간 피드백 + 오늘의 한마디 생성
 */
async function generateBreathingFeedback(req, res) {
  try {
    const { routineName = "4-6 릴렉스 호흡", durationSeconds = 180, cycleCount = 3, conditionScore = 80 } = req.body;
    const durationString = formatDuration(durationSeconds);

    const promptData = {
      routineName,
      durationString,
      cycleCount,
      conditionScore
    };

    const promptText = buildSlotBPrompt(promptData);

    // 실시간 Gemini AI 호출 (실패 시 에러 처리)
    let aiResult;
    try {
      aiResult = await generateAiContent(promptText);
    } catch (aiError) {
      return sendError(
        res,
        aiError.code || 'AI_SERVICE_UNAVAILABLE',
        aiError.userMessage || '현재 AI 분석을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.',
        503
      );
    }

    return sendSuccess(res, {
      headline: aiResult.headline,
      summaryText: aiResult.summaryText,
      feedbackText: aiResult.feedbackText,
      todaysQuote: aiResult.todaysQuote
    });
  } catch (error) {
    console.error('[generateBreathingFeedback Error]:', error);
    return sendError(res, 'INTERNAL_SERVER_ERROR', '호흡 피드백 생성 중 오류가 발생했습니다.', 500);
  }
}

module.exports = {
  getLatestReport,
  generateRealtimeReport,
  generateBreathingFeedback
};
