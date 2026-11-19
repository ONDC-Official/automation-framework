#!/usr/bin/env node
/*
 * Local stand-in for the ONDC registry's /lookup, for the local workbench stack.
 *
 * The ONIX api-service verifies every signed request by POSTing
 * {subscriber_id, ukId} to `${IN_HOUSE_REGISTRY}lookup` and reading
 * `[0].signing_public_key`. Locally every party is the workbench itself (both
 * the mock and the "NP" are the api-service), so every lookup answers with the
 * workbench's own public key. No real registry is contacted.
 *
 * Usage: SIGNING_PUBLIC=<base64 ed25519 pub> node scripts/local-registry.js [port]
 *        (port defaults to REGISTRY_PORT or 5010)
 */
const http = require('node:http');

const port = Number(process.argv[2] || process.env.REGISTRY_PORT || 5010);
const signingPublic = process.env.SIGNING_PUBLIC;
if (!signingPublic) {
    console.error('local-registry: SIGNING_PUBLIC is required');
    process.exit(1);
}

http.createServer((req, res) => {
    let body = '';
    req.on('data', (c) => (body += c));
    req.on('end', () => {
        if (req.method === 'POST' && req.url.replace(/\/+$/, '').endsWith('/lookup')) {
            let q = {};
            try {
                q = JSON.parse(body || '{}');
            } catch {}
            console.log(`[registry] lookup subscriber_id=${q.subscriber_id} ukId=${q.ukId}`);
            res.writeHead(200, { 'content-type': 'application/json' });
            res.end(
                JSON.stringify([
                    {
                        subscriber_id: q.subscriber_id,
                        ukId: q.ukId,
                        status: 'SUBSCRIBED',
                        signing_public_key: signingPublic,
                        encr_public_key: signingPublic,
                    },
                ])
            );
            return;
        }
        res.writeHead(req.url === '/health' ? 200 : 404, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ ok: req.url === '/health' }));
    });
}).listen(port, () => console.log(`[registry] listening on :${port}`));
