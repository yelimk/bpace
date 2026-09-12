/**
 * BPACE Step 6 AI 리포트 및 피드백 API 검증 스크립트
 */

const app = require('../app');
const http = require('http');

async function runTest() {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  console.log(`[Test] 테스트 서버 가동 (Port: ${port})`);

  try {
    // 1. GET /api/reports/latest (최근 보고서 조회)
    console.log('\n--- [Test 1] GET /api/reports/latest ---');
    const getRes = await fetch(`${baseUrl}/api/reports/latest`);
    const getJson = await getRes.json();
    console.log('GET /latest 응답:', JSON.stringify(getJson, null, 2));

    // 2. POST /api/reports/feedback (슬롯 B 호흡 피드백 + 오늘의 한마디)
    console.log('\n--- [Test 2] POST /api/reports/feedback ---');
    const feedbackRes = await fetch(`${baseUrl}/api/reports/feedback`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        routineName: '4-6 릴렉스 호흡',
        durationSeconds: 180,
        cycleCount: 3,
        conditionScore: 82
      })
    });
    const feedbackJson = await feedbackRes.json();
    console.log(`POST /feedback 응답 (HTTP ${feedbackRes.status}):`, JSON.stringify(feedbackJson, null, 2));

    // 3. POST /api/reports/analyze (슬롯 A 실시간 생체 데이터 분석)
    console.log('\n--- [Test 3] POST /api/reports/analyze ---');
    const analyzeRes = await fetch(`${baseUrl}/api/reports/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        avgBpm: 82,
        maxBpm: 94,
        minBpm: 68,
        hrvSdnnMs: 45,
        conditionScore: 80
      })
    });
    const analyzeJson = await analyzeRes.json();
    console.log(`POST /analyze 응답 (HTTP ${analyzeRes.status}):`, JSON.stringify(analyzeJson, null, 2));

    console.log('\n✅ [Test Complete] Step 6 AI 리포트 API 검증 완료!');
  } catch (err) {
    console.error('❌ 테스트 중 에러 발생:', err.message);
  } finally {
    server.close();
  }
}

runTest();
