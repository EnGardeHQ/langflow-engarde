/**
 * Real login test - simulates what happens when you actually try to log in
 */

const http = require('http');

async function testLogin(email, password) {
  console.log(`\n🔑 Testing login for: ${email}`);
  console.log('=' .repeat(60));

  // Create form data
  const formData = `username=${encodeURIComponent(email)}&password=${encodeURIComponent(password)}`;

  const options = {
    hostname: 'localhost',
    port: 8000,
    path: '/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(formData)
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log(`\n📡 Response Status: ${res.statusCode}`);
        console.log(`📡 Response Headers:`, res.headers);
        console.log(`📡 Response Body:`, data);

        try {
          const parsed = JSON.parse(data);
          console.log(`\n📊 Parsed Response:`, JSON.stringify(parsed, null, 2));

          if (res.statusCode === 200 && parsed.access_token) {
            console.log(`\n✅ LOGIN SUCCESSFUL`);
            console.log(`   Token: ${parsed.access_token.substring(0, 50)}...`);
            console.log(`   User: ${parsed.user?.email || 'unknown'}`);
            resolve({ success: true, data: parsed });
          } else {
            console.log(`\n❌ LOGIN FAILED`);
            console.log(`   Reason: ${parsed.detail || 'Unknown error'}`);
            resolve({ success: false, error: parsed.detail });
          }
        } catch (e) {
          console.log(`\n❌ PARSE ERROR:`, e.message);
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.error(`\n❌ REQUEST ERROR:`, e.message);
      reject(e);
    });

    req.write(formData);
    req.end();
  });
}

async function main() {
  console.log('\n🧪 REAL LOGIN FLOW TEST');
  console.log('Testing actual backend authentication...\n');

  // Test with various credentials
  const testCases = [
    { email: 'test@example.com', password: 'password123' },
    { email: 'test@example.com', password: 'testpassword' },
    { email: 'test@example.com', password: 'admin123' },
    { email: 'demo@engarde.ai', password: 'password123' },
    { email: 'demo@engarde.ai', password: 'demo123' },
  ];

  for (const testCase of testCases) {
    try {
      await testLogin(testCase.email, testCase.password);
    } catch (e) {
      console.error('Test failed:', e);
    }
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  console.log('\n' + '='.repeat(60));
  console.log('Test complete. Check results above.');
  console.log('='.repeat(60) + '\n');
}

main().catch(console.error);
