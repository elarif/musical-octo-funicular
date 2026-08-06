import { existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const playwrightPath = join(here, 'capture-deps', 'node_modules', 'playwright', 'index.js');

if (!existsSync(playwrightPath)) {
  console.error('[capture] playwright not installed. Run: (cd ' + join(here, 'capture-deps') + ' && npm install && npx playwright install chromium)');
  process.exit(2);
}

const { chromium } = await import('file://' + playwrightPath);

const url = process.argv[2];
const slug = process.argv[3] || 'capture';

if (!url) {
  console.error('usage: capture.mjs <url> [slug]');
  process.exit(1);
}

const stateDir = join(process.env.HOME, '.config', 'kibana-skill', 'browser-state');
const shotsDir = join(process.env.HOME, '.config', 'kibana-skill', 'screenshots');
mkdirSync(stateDir, { recursive: true });
mkdirSync(shotsDir, { recursive: true });

const ts = new Date().toISOString().replace(/[:.]/g, '-');
const outPath = join(shotsDir, `${ts}-${slug}.png`);

const context = await chromium.launchPersistentContext(stateDir, {
  headless: false,
  viewport: { width: 1440, height: 900 }
});

try {
  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 }).catch(() => {});

  const appReady = await page.waitForSelector('[data-test-subj="kibanaChrome"], #kibana-root, app-root', { timeout: 90000 }).catch(() => null);
  if (!appReady) {
    console.error('[capture] Kibana app not detected — waiting for manual login. Please log in the browser window.');
    await page.waitForSelector('[data-test-subj="kibanaChrome"], #kibana-root, app-root', { timeout: 300000 }).catch(() => {
      throw new Error('login timeout');
    });
  }

  const tableSel = '[data-test-subj="docExplorerTable"], [data-test-subj="unifiedDocTable"]';
  await page.waitForSelector(tableSel, { timeout: 30000 }).catch(() => {
    console.error('[capture] warning: Discover table not found after 30s');
  });

  await page.waitForTimeout(3000);
  await page.screenshot({ path: outPath, type: 'png', fullPage: false });
  console.log(outPath);
} catch (err) {
  console.error(`[capture] failed: ${err.message}`);
  process.exit(1);
} finally {
  await context.close();
}