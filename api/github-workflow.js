import crypto from 'node:crypto';

const EXPECTED_REPOSITORY = 'aloisiocosta-prof/universal-ssh';

function verifySignature(rawBody, signature, secret) {
  if (!secret || !signature?.startsWith('sha256=')) return false;
  const expected = 'sha256=' + crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
  const a = Buffer.from(expected);
  const b = Buffer.from(signature);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body ?? {});
  const signature = req.headers['x-hub-signature-256'];

  if (!verifySignature(rawBody, signature, process.env.GITHUB_WEBHOOK_SECRET)) {
    return res.status(401).json({ error: 'invalid_signature' });
  }

  const event = req.headers['x-github-event'];
  if (event !== 'workflow_run') return res.status(202).json({ ignored: event });

  const payload = typeof req.body === 'object' ? req.body : JSON.parse(rawBody);
  if (payload.repository?.full_name !== EXPECTED_REPOSITORY) {
    return res.status(403).json({ error: 'unexpected_repository' });
  }

  const run = payload.workflow_run;
  if (payload.action !== 'completed' || run?.conclusion !== 'failure') {
    return res.status(202).json({ ignored: 'not_failed_workflow' });
  }

  const envelope = {
    event: 'workflow.failed',
    repository: payload.repository.full_name,
    workflow: run.name,
    run_id: run.id,
    run_url: run.html_url,
    head_sha: run.head_sha,
    pull_requests: (run.pull_requests ?? []).map(pr => pr.number),
    conclusion: run.conclusion
  };

  // Generic agent ingress. This must be an endpoint that can actually start
  // an agent run; do not point it at an ordinary notification-only webhook.
  if (!process.env.AGENT_INGRESS_URL) {
    console.error('workflow.failed', envelope);
    return res.status(503).json({ error: 'agent_ingress_not_configured', envelope });
  }

  const upstream = await fetch(process.env.AGENT_INGRESS_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(process.env.AGENT_INGRESS_TOKEN
        ? { authorization: `Bearer ${process.env.AGENT_INGRESS_TOKEN}` }
        : {})
    },
    body: JSON.stringify(envelope)
  });

  if (!upstream.ok) {
    const body = await upstream.text();
    console.error('agent ingress rejected event', upstream.status, body);
    return res.status(502).json({ error: 'agent_ingress_failed', status: upstream.status });
  }

  return res.status(202).json({ accepted: true, envelope });
}
