// Test script to call /api/agents/installed with authentication
// Run this in the browser console on https://app.engarde.media

async function testAgentsRetrieval() {
    try {
        // Get the auth token from localStorage or cookies
        const token = localStorage.getItem('access_token') || 
                     document.cookie.split(';').find(c => c.trim().startsWith('access_token='))?.split('=')[1];
        
        if (!token) {
            console.error('❌ No access token found. Please log in first.');
            return;
        }
        
        console.log('🔍 Testing /api/agents/installed endpoint...');
        console.log('Token:', token.substring(0, 50) + '...');
        
        const response = await fetch('https://api.engarde.media/api/agents/installed?page=1&pageSize=12&sortBy=name&sortOrder=asc', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });
        
        console.log('📊 Response Status:', response.status);
        console.log('📊 Response Headers:', Object.fromEntries(response.headers.entries()));
        
        const data = await response.json();
        console.log('📊 Response Data (Pretty Printed):');
        console.log(JSON.stringify(data, null, 2));
        
        if (response.ok) {
            console.log('✅ Success!');
            console.log(`Found ${data.items?.length || 0} agents`);
            console.log(`Total: ${data.total || 0}`);
        } else {
            console.error('❌ Error:', data);
        }
        
        return data;
    } catch (error) {
        console.error('❌ Request failed:', error);
    }
}

// Also test the debug endpoint
async function testDebugEndpoint() {
    try {
        const token = localStorage.getItem('access_token') || 
                     document.cookie.split(';').find(c => c.trim().startsWith('access_token='))?.split('=')[1];
        
        console.log('🔍 Testing /api/agents/debug/retrieval endpoint...');
        
        const headers = {
            'Content-Type': 'application/json'
        };
        
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }
        
        const response = await fetch('https://api.engarde.media/api/agents/debug/retrieval', {
            method: 'GET',
            headers: headers
        });
        
        const data = await response.json();
        console.log('📊 Debug Endpoint Response (Pretty Printed):');
        console.log(JSON.stringify(data, null, 2));
        
        return data;
    } catch (error) {
        console.error('❌ Debug endpoint request failed:', error);
    }
}

// Run both tests
console.log('🚀 Starting agent retrieval tests...');
testAgentsRetrieval().then(() => {
    console.log('\n');
    testDebugEndpoint();
});
