const http = require('http');

function request(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTest() {
  console.log('=== Step 4 API Integration Test ===');

  // 1. POST /api/breathing-logs
  const postLogRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: '/api/breathing-logs',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, {
    category: '진정',
    routineName: '4-7-8 호흡',
    durationSeconds: 300,
    completionRate: 100.0,
    userNotes: '스텝4 자동화 연동 테스트 완료'
  });
  console.log('1. POST /api/breathing-logs Status:', postLogRes.status);
  console.log('Response:', JSON.stringify(postLogRes.data, null, 2));

  // 2. GET /api/breathing-logs
  const getLogsRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: '/api/breathing-logs',
    method: 'GET'
  });
  console.log('\n2. GET /api/breathing-logs Status:', getLogsRes.status);
  console.log('Total Logs Count:', getLogsRes.data?.data?.length);

  // 3. GET /api/statistics/summary
  const getSummaryRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: '/api/statistics/summary',
    method: 'GET'
  });
  console.log('\n3. GET /api/statistics/summary Status:', getSummaryRes.status);
  console.log('Summary Data:', JSON.stringify(getSummaryRes.data, null, 2));

  // 4. GET /api/statistics/daily
  const getDailyRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: '/api/statistics/daily',
    method: 'GET'
  });
  console.log('\n4. GET /api/statistics/daily Status:', getDailyRes.status);
  console.log('Daily Data:', JSON.stringify(getDailyRes.data, null, 2));

  if (postLogRes.status === 201 && getSummaryRes.data?.success) {
    console.log('\n✅ Step 4 Breathing Log & Statistics API All Tests Passed!');
  } else {
    console.error('\n❌ Test Failed');
    process.exit(1);
  }
}

runTest().catch(err => {
  console.error('Test Execution Error:', err);
  process.exit(1);
});
