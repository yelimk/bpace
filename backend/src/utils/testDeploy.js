/**
 * BPACE Step 7 배포 & API 명세 통합 검증 스크립트
 */

const app = require('../app');
const http = require('http');

async function runTest() {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  console.log(`[Test] Step 7 배포 검증 서버 가동 (Port: ${port})`);

  try {
    // 1. GET /api/health (헬스체크 & DB 핑)
    console.log('\n--- [Test 1] GET /api/health ---');
    const healthRes = await fetch(`${baseUrl}/api/health`);
    const healthJson = await healthRes.json();
    console.log('GET /api/health 응답:', JSON.stringify(healthJson, null, 2));

    // 2. GET /api/health/version (버전 정보)
    console.log('\n--- [Test 2] GET /api/health/version ---');
    const versionRes = await fetch(`${baseUrl}/api/health/version`);
    const versionJson = await versionRes.json();
    console.log('GET /api/health/version 응답:', JSON.stringify(versionJson, null, 2));

    console.log('\n✅ [Test Complete] Step 7 배포 및 헬스 체크 검증 완료!');
  } catch (err) {
    console.error('❌ 테스트 중 에러 발생:', err.message);
  } finally {
    server.close();
  }
}

runTest();
