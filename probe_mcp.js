const fs = require('fs');

// Try different MCP endpoints and transports
const endpoints = ['/sse', '/events', '/api', '/rpc', '/tools/call', '/v1'];
const base = 'http://localhost:16384';

async function tryEndpoint(path) {
    try {
        const res = await fetch(base + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                jsonrpc: '2.0',
                method: 'tools/call',
                id: 1,
                params: { name: 'list-clients', arguments: {} }
            })
        });
        const text = await res.text();
        console.log(`POST ${path} [${res.status}]: ${text.substring(0, 200)}`);
    } catch (e) {
        console.log(`POST ${path} ERROR: ${e.message}`);
    }
}

async function tryGet(path) {
    try {
        const res = await fetch(base + path);
        const text = await res.text();
        console.log(`GET  ${path} [${res.status}]: ${text.substring(0, 200)}`);
    } catch (e) {
        console.log(`GET  ${path} ERROR: ${e.message}`);
    }
}

async function main() {
    // Try GET on base
    await tryGet('/');
    await tryGet('/sse');
    
    // Try POST on various endpoints
    for (const ep of endpoints) {
        await tryEndpoint(ep);
    }

    // Also try the executor-specific API (Ro-Exec, Solara, etc.)
    // Common executor HTTP APIs
    const execApis = [
        { url: base + '/api/execute', body: JSON.stringify({ script: 'print("hello")' }) },
        { url: base + '/execute', body: 'print("hello")' },
    ];
    for (const api of execApis) {
        try {
            const res = await fetch(api.url, {
                method: 'POST',
                headers: { 'Content-Type': 'text/plain' },
                body: api.body
            });
            const text = await res.text();
            console.log(`POST ${api.url} [${res.status}]: ${text.substring(0, 200)}`);
        } catch (e) {
            console.log(`POST ${api.url} ERROR: ${e.message}`);
        }
    }
}

main();
