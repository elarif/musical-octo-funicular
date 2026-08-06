import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const risonPath = join(here, 'kibana-url-deps', 'node_modules', 'rison', 'js', 'rison.js');

if (!existsSync(risonPath)) {
  console.error('[kibana-url] rison not installed. Run: (cd ' + join(here, 'kibana-url-deps') + ' && npm install)');
  process.exit(2);
}

const risonModule = await import('file://' + risonPath);
const rison = risonModule.default || risonModule;

async function loadEnv() {
  const envPath = join(process.env.HOME, '.config', 'kibana-skill', 'env');
  const content = await readFile(envPath, 'utf8');
  const env = {};
  for (const line of content.split('\n')) {
    const m = line.match(/^([A-Z_]+)=(.*)$/);
    if (m) env[m[1]] = m[2];
  }
  return env;
}

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 2) {
    const k = argv[i]?.replace(/^--/, '');
    args[k] = argv[i + 1];
  }
  return args;
}

const args = parseArgs(process.argv);
const env = await loadEnv();
const KIBANA_BASE_URL = env.KIBANA_BASE_URL || '';
const KIBANA_SPACE = args.space || env.KIBANA_SPACE || 'default';

if (!KIBANA_BASE_URL) {
  console.error('[kibana-url] KIBANA_BASE_URL not set in env');
  process.exit(1);
}
if (!args.index || !args.query || !args.from || !args.to) {
  console.error('usage: kibana-url.mjs --index <pattern> --query <kql> --from <iso> --to <iso> --columns <csv> [--space <space>]');
  process.exit(1);
}

const columns = (args.columns || '').split(',').map((s) => s.trim()).filter(Boolean);

const state = {
  indexPattern: { title: args.index },
  query: { query: args.query, language: 'kuery' },
  filters: [],
  timeRange: { from: args.from, to: args.to },
  columns
};

function buildUrl(s) {
  const encoded = rison.encode_object(s);
  if (encoded.includes('#')) throw new Error('rison contains #');
  rison.decode_object(encoded);
  const spacePart = KIBANA_SPACE === 'default' ? '' : `/s/${KIBANA_SPACE}`;
  return `${KIBANA_BASE_URL}${spacePart}/app/discover#/view?_a=${encoded}`;
}

const spacePart = KIBANA_SPACE === 'default' ? '' : `/s/${KIBANA_SPACE}`;
try {
  const url = buildUrl(state);
  console.log(url);
} catch (err) {
  try {
    console.log(`${KIBANA_BASE_URL}${spacePart}/app/discover#?_g=(time:(from:'${args.from}',to:'${args.to}'))`);
  } catch {
    console.log(`${KIBANA_BASE_URL}${spacePart}/app/discover`);
  }
  console.error(`[kibana-url] encoding failed: ${err.message}`);
  console.error(`[kibana-url] KQL to paste manually: ${args.query}`);
}