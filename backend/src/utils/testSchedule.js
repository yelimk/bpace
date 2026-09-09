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
  console.log('=== Step 5 Calendar Schedule API Integration Test ===');

  const now = new Date();
  const startTimeIn10Min = new Date(now.getTime() + 10 * 60 * 1000).toISOString();
  const endTimeIn70Min = new Date(now.getTime() + 70 * 60 * 1000).toISOString();

  // 1. POST /api/schedules
  const createRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: '/api/schedules',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, {
    title: '프로젝트 중요 발표 및 데모',
    startTime: startTimeIn10Min,
    endTime: endTimeIn70Min,
    category: '몰입'
  });
  console.log('1. POST /api/schedules Status:', createRes.status);
  console.log('Created Schedule:', JSON.stringify(createRes.data, null, 2));

  const scheduleId = createRes.data?.data?.id;

  // 2. GET /api/schedules?upcomingOnly=true
  const upcomingRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: '/api/schedules?upcomingOnly=true',
    method: 'GET'
  });
  console.log('\n2. GET /api/schedules?upcomingOnly=true Status:', upcomingRes.status);
  console.log('Upcoming Schedules Count:', upcomingRes.data?.data?.length);

  // 3. PATCH /api/schedules/:id/complete
  const completeRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: `/api/schedules/${scheduleId}/complete`,
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' }
  }, {
    completed: true
  });
  console.log('\n3. PATCH /api/schedules/:id/complete Status:', completeRes.status);

  // 4. PUT /api/schedules/:id
  const updateRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: `/api/schedules/${scheduleId}`,
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' }
  }, {
    title: '[완료됨] 프로젝트 중요 발표 및 데모'
  });
  console.log('\n4. PUT /api/schedules/:id Status:', updateRes.status);

  // 5. DELETE /api/schedules/:id
  const deleteRes = await request({
    hostname: 'localhost',
    port: 3000,
    path: `/api/schedules/${scheduleId}`,
    method: 'DELETE'
  });
  console.log('\n5. DELETE /api/schedules/:id Status:', deleteRes.status);

  if (createRes.status === 201 && upcomingRes.status === 200 && deleteRes.status === 200) {
    console.log('\n✅ Step 5 Calendar Schedule CRUD API All Tests Passed!');
  } else {
    console.error('\n❌ Step 5 Test Failed');
    process.exit(1);
  }
}

runTest().catch(err => {
  console.error('Test Execution Error:', err);
  process.exit(1);
});
