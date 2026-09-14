const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const OUT_DIR = path.join(__dirname, 'assets', 'fonts');

// TTF files from Google Fonts GitHub (raw, direct download)
const FONT_FILES = [
  // ─── Inter (OFL licensed) ───────────────────────────────────────────────
  {
    url: 'https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf',
    file: 'Inter-Variable.ttf',
  },
  // ─── Plus Jakarta Sans (OFL licensed) ──────────────────────────────────
  {
    url: 'https://github.com/google/fonts/raw/main/ofl/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf',
    file: 'PlusJakartaSans-Variable.ttf',
  },
  {
    url: 'https://github.com/google/fonts/raw/main/ofl/plusjakartasans/PlusJakartaSans-Italic%5Bwght%5D.ttf',
    file: 'PlusJakartaSans-VariableItalic.ttf',
  },
];

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(dest);
    client.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        file.close();
        fs.unlinkSync(dest);
        return download(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        file.close();
        fs.unlinkSync(dest);
        return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      }
      res.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function main() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
  for (const { url, file } of FONT_FILES) {
    const dest = path.join(OUT_DIR, file);
    if (fs.existsSync(dest) && fs.statSync(dest).size > 1000) {
      console.log(`✓ Already exists: ${file}`);
      continue;
    }
    process.stdout.write(`Downloading ${file}...`);
    await download(url, dest);
    console.log(` done (${fs.statSync(dest).size} bytes)`);
  }
  console.log('\n✅ All fonts downloaded.');
}

main().catch(console.error);
