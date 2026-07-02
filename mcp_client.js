const fs = require('fs');
const http = require('http');
const EventSource = require && null; // no npm package available

// MCP SSE Transport: 
// 1. GET /sse -> SSE stream (receives session endpoint URL)  
// 2. POST to session endpoint with JSON-RPC messages

const BASE = 'http://localhost:16384';

// Step 1: Connect to SSE and get the message endpoint
function connectSSE() {
    return new Promise((resolve, reject) => {
        const url = new URL(BASE + '/sse');
        const req = http.get(url, (res) => {
            let buffer = '';
            res.on('data', (chunk) => {
                buffer += chunk.toString();
                // Parse SSE events
                const lines = buffer.split('\n');
                for (const line of lines) {
                    if (line.startsWith('data: ')) {
                        const data = line.substring(6).trim();
                        console.log('SSE data:', data);
                        // The first message should contain the endpoint URL
                        if (data.startsWith('/') || data.startsWith('http')) {
                            resolve(data);
                            return;
                        }
                        // Try parsing as JSON
                        try {
                            const json = JSON.parse(data);
                            console.log('SSE JSON:', JSON.stringify(json).substring(0, 500));
                        } catch(e) {}
                    } else if (line.startsWith('event: ')) {
                        console.log('SSE event:', line);
                    }
                }
            });
            res.on('error', reject);
            // Timeout after 3 seconds
            setTimeout(() => {
                req.destroy();
                reject(new Error('SSE timeout - no endpoint received'));
            }, 3000);
        });
        req.on('error', reject);
    });
}

// Step 2: Send JSON-RPC to the message endpoint
async function callTool(endpoint, toolName, args) {
    const body = JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/call',
        id: Date.now(),
        params: { name: toolName, arguments: args }
    });
    
    const fullUrl = endpoint.startsWith('http') ? endpoint : BASE + endpoint;
    const res = await fetch(fullUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body
    });
    const text = await res.text();
    return text;
}

async function main() {
    try {
        console.log('Connecting to MCP SSE...');
        const endpoint = await connectSSE();
        console.log('Got endpoint:', endpoint);
        
        // List clients
        const result = await callTool(endpoint, 'list-clients', {});
        console.log('list-clients result:', result);
    } catch (e) {
        console.log('Error:', e.message);
    }
}

main();
