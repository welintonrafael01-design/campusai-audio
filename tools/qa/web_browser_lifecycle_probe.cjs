#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const [secretsPath, baseUrl, outputDir] = process.argv.slice(2);

if (!secretsPath || !baseUrl || !outputDir) {
  throw new Error('Usage: web_browser_lifecycle_probe.cjs <secrets> <url> <output>');
}

const secrets = JSON.parse(fs.readFileSync(secretsPath, 'utf8'));
const required = [
  'API_BASE_URL',
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'QA_STUDENT_A_EMAIL',
  'QA_STUDENT_A_PASSWORD',
  'QA_STUDENT_B_EMAIL',
  'QA_STUDENT_B_PASSWORD',
];

for (const key of required) {
  if (!String(secrets[key] || '').trim()) {
    throw new Error(`Missing required QA configuration: ${key}`);
  }
}

fs.mkdirSync(outputDir, { recursive: true });

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function projectRef() {
  return new URL(secrets.SUPABASE_URL).hostname.split('.')[0];
}

async function authenticate(email, password) {
  const response = await fetch(
    `${secrets.SUPABASE_URL}/auth/v1/token?grant_type=password`,
    {
      method: 'POST',
      headers: {
        apikey: secrets.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${secrets.SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    },
  );
  assert(response.ok, `Supabase authentication failed with ${response.status}`);
  return response.json();
}

async function subscriptionFor(session) {
  const response = await fetch(
    `${String(secrets.API_BASE_URL).replace(/\/$/, '')}/billing/subscription/me`,
    { headers: { Authorization: `Bearer ${session.access_token}` } },
  );
  assert(response.ok, `Subscription API failed with ${response.status}`);
  return response.json();
}

async function setSession(page, storageKey, session) {
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
  await page.evaluate(
    ({ key, value }) => window.localStorage.setItem(key, value),
    { key: storageKey, value: JSON.stringify(session) },
  );
}

async function storedUserId(page, storageKey) {
  return page.evaluate((key) => {
    const raw = window.localStorage.getItem(key);
    if (!raw) return null;
    try {
      return JSON.parse(raw)?.user?.id || null;
    } catch (_) {
      return null;
    }
  }, storageKey);
}

async function waitForFlutter(page, expectedHash) {
  await page.waitForFunction(
    (hash) =>
      window.location.hash.startsWith(hash) &&
      Boolean(document.querySelector('flutter-view, flt-glass-pane')),
    expectedHash,
    { timeout: 60000 },
  );
  await page.waitForTimeout(2500);
}

async function openRoute(page, route) {
  await page.goto(`${baseUrl}/#${route}`, { waitUntil: 'domcontentloaded' });
  await waitForFlutter(page, `#${route}`);
}

async function main() {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  let page = await context.newPage();
  const unexpected = [];

  const observePage = (target) => {
    target.on('pageerror', (error) => unexpected.push(`pageerror: ${error.message}`));
    target.on('console', (message) => {
      if (message.type() !== 'error') return;
      const text = message.text();
      if (text.includes('favicon.ico') || text.includes('manifest.json')) return;
      unexpected.push(`console: ${text}`);
    });
    target.on('response', (response) => {
      if (response.status() >= 500) {
        unexpected.push(`network: ${response.status()} ${new URL(response.url()).pathname}`);
      }
    });
  };
  observePage(page);

  try {
    const storageKey = `sb-${projectRef()}-auth-token`;
    const studentA = await authenticate(
      secrets.QA_STUDENT_A_EMAIL,
      secrets.QA_STUDENT_A_PASSWORD,
    );
    const studentASubscription = await subscriptionFor(studentA);
    assert(studentASubscription.plan === 'student', 'Student A plan mismatch');
    assert(
      studentASubscription.subscription_status === 'active',
      'Student A subscription is not active',
    );

    await setSession(page, storageKey, studentA);
    await openRoute(page, '/library');
    const beforeReloadUser = await storedUserId(page, storageKey);
    assert(beforeReloadUser === studentA.user.id, 'Student A session was not persisted');
    await page.screenshot({ path: path.join(outputDir, 'library-before-reload.png') });

    await page.reload({ waitUntil: 'domcontentloaded' });
    await waitForFlutter(page, '#/library');
    const afterReloadUser = await storedUserId(page, storageKey);
    assert(afterReloadUser === studentA.user.id, 'Hard reload changed the authenticated identity');
    await page.screenshot({ path: path.join(outputDir, 'library-after-reload.png') });
    console.log('E2E_RESULT HARD_RELOAD=PASS');

    await page.close();
    page = await context.newPage();
    observePage(page);
    await openRoute(page, '/library');
    const afterTabReopenUser = await storedUserId(page, storageKey);
    assert(
      afterTabReopenUser === studentA.user.id,
      'Closing and reopening the tab did not restore Student A',
    );
    console.log('E2E_RESULT TAB_REOPEN=PASS');

    await openRoute(page, '/dashboard');
    await openRoute(page, '/library');
    await page.goBack({ waitUntil: 'domcontentloaded' });
    await waitForFlutter(page, '#/dashboard');
    await page.goForward({ waitUntil: 'domcontentloaded' });
    await waitForFlutter(page, '#/library');
    console.log('E2E_RESULT BACK_FORWARD=PASS');

    await page.setViewportSize({ width: 390, height: 844 });
    await openRoute(page, '/dashboard');
    await page.screenshot({ path: path.join(outputDir, 'dashboard-390.png'), fullPage: true });
    await openRoute(page, '/library');
    await openRoute(page, '/learning');
    await page.screenshot({ path: path.join(outputDir, 'learning-390.png'), fullPage: true });
    console.log('E2E_RESULT LEARNING=PASS');
    await openRoute(page, '/account');
    console.log('E2E_RESULT RESPONSIVE_BROWSER=PASS');

    await page.evaluate((key) => window.localStorage.removeItem(key), storageKey);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await waitForFlutter(page, '#/auth');

    const studentB = await authenticate(
      secrets.QA_STUDENT_B_EMAIL,
      secrets.QA_STUDENT_B_PASSWORD,
    );
    const studentBSubscription = await subscriptionFor(studentB);
    assert(studentBSubscription.plan === 'student', 'Student B plan mismatch');
    assert(
      studentBSubscription.subscription_status === 'active',
      'Student B subscription is not active',
    );
    await setSession(page, storageKey, studentB);
    await openRoute(page, '/dashboard');
    assert(
      (await storedUserId(page, storageKey)) === studentB.user.id,
      'Browser cache retained Student A identity',
    );
    console.log('E2E_RESULT BROWSER_SESSION_SWITCH=PASS');

    assert(unexpected.length === 0, unexpected.join('\n'));
    fs.writeFileSync(
      path.join(outputDir, 'browser-probe.json'),
      JSON.stringify(
        {
          hard_reload: 'PASS',
          tab_reopen: 'PASS',
          back_forward: 'PASS',
          responsive: 'PASS',
          session_switch: 'PASS',
          unexpected_errors: 0,
        },
        null,
        2,
      ),
    );
    console.log('E2E_RESULT BROWSER_LIFECYCLE=PASS');
  } finally {
    await context.clearCookies();
    await browser.close();
  }
}

main().catch((error) => {
  const safeMessage = String(error?.message || error)
    .replace(/Bearer\s+[A-Za-z0-9._-]+/gi, 'Bearer [REDACTED]')
    .replace(/eyJ[A-Za-z0-9._-]+/g, '[REDACTED_TOKEN]');
  console.error(`WEB_BROWSER_PROBE_FAILED: ${safeMessage}`);
  process.exitCode = 1;
});
