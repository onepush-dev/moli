# Moli on Railway

Moli — a lite, fast headless browser for AI agents (CDP, WebDriver Classic and WebDriver BiDi), built in Rust. Deploy on Railway with one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/J008-8)

This repository packages the official [Moli](https://github.com/lexmount/moli) v1.1.22 Linux release binary (Apache-2.0 OR MIT) for Railway. It is an independent community packaging, not affiliated with or endorsed by Lexmount.

## How it is wired

- `moli serve --layout --block-private-networks` listens on `127.0.0.1:9223` only. Upstream warns never to expose raw CDP, so nothing reaches it directly.
- nginx on the public port forwards **only** `/t/<MOLI_TOKEN>/…` to Moli. `MOLI_TOKEN` is generated per deploy, so the endpoint is a secret URL that works with any client (no custom headers needed).
- Discovery JSON (`/json/version`, `/json/list`) is rewritten so `webSocketDebuggerUrl` points at `wss://<your-domain>/t/<token>/…`.
- `/healthz` (Railway healthcheck) and `/` (a short hint) are the only other routes. Everything else is 404.

## Connect

Copy `MOLI_CDP_URL` from the service's Variables tab (it is `https://<domain>/t/<MOLI_TOKEN>`).

```js
import { chromium } from "playwright";
const browser = await chromium.connectOverCDP(process.env.MOLI_CDP_URL);
const context = browser.contexts()[0];
const page = context.pages()[0] ?? await context.newPage();
await page.goto("https://example.com");
console.log(await page.locator("body").innerText());
await browser.close();
```

Puppeteer: `puppeteer.connect({ browserURL: MOLI_CDP_URL })`. Selenium / WebDriver: use `MOLI_CDP_URL` as the remote URL. Services in the same Railway project can skip the proxy only if you change the bind address, which is not recommended.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `MOLI_TOKEN` | generated | Secret path segment that guards the endpoint. Rotate it to revoke access. |
| `MOLI_CDP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}/t/${{MOLI_TOKEN}}` | Convenience: the full endpoint to paste into your agent |
| `MOLI_SERVE_ARGS` | `--layout --block-private-networks` (image default) | Extra `moli serve` flags, e.g. add `--resource` to fetch images/fonts/media, `--obey-robots` to honour robots.txt. `--block-private-networks` stops pages from reaching private/internal addresses (incl. other Railway services). |

## Notes

- Treat `MOLI_CDP_URL` like a password: anyone with it can drive the browser (and make requests from your Railway egress IP).
- Moli keeps no state you need to persist, so there is no volume.
- To upgrade, bump `MOLI_VERSION` / `MOLI_SHA256` in the `Dockerfile`; GitHub Actions rebuilds `ghcr.io/onepush-dev/moli`.
