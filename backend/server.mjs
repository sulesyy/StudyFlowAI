import http from "node:http";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

function loadLocalEnv() {
  try {
    const contents = readFileSync(fileURLToPath(new URL("./.env", import.meta.url)), "utf8");
    for (const rawLine of contents.split(/\r?\n/)) {
      const line = rawLine.trim().replace(/^export\s+/, "");
      if (!line || line.startsWith("#")) continue;
      const separator = line.indexOf("=");
      if (separator < 1) continue;
      const name = line.slice(0, separator).trim();
      if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name) || process.env[name] !== undefined) continue;
      let value = line.slice(separator + 1).trim();
      if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      process.env[name] = value;
    }
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
}

loadLocalEnv();

const host = process.env.HOST ?? "127.0.0.1";
const port = Number(process.env.PORT ?? 3000);
const model = process.env.GEMINI_MODEL ?? "gemini-3.8-flash";
const maxBodyBytes = 300_000;
const windows = new Map();

function reply(res, status, body) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  res.end(JSON.stringify(body));
}

function allowed(ip) {
  const now = Date.now();
  const window = windows.get(ip);
  if (!window || now - window.start > 60_000) { windows.set(ip, { start: now, count: 1 }); return true; }
  window.count += 1;
  return window.count <= 20;
}

const server = http.createServer(async (req, res) => {
  if (req.method === "GET" && req.url === "/health") return reply(res, 200, { status: "ok", aiConfigured: Boolean(process.env.GEMINI_API_KEY?.trim()) });
  if (req.method !== "POST" || req.url !== "/generate") return reply(res, 404, { error: "Endpoint bulunamadı." });
  if (!allowed(req.socket.remoteAddress ?? "unknown")) return reply(res, 429, { error: "Çok fazla istek gönderildi. Biraz sonra tekrar dene." });
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return reply(res, 503, { error: "AI sunucusunda GEMINI_API_KEY ayarlanmamış." });

  try {
    const chunks = [];
    let bytes = 0;
    for await (const chunk of req) {
      bytes += chunk.length;
      if (bytes > maxBodyBytes) return reply(res, 413, { error: "İstek çok büyük." });
      chunks.push(chunk);
    }
    const input = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    const prompt = typeof input.prompt === "string" ? input.prompt.trim() : "";
    if (!prompt) return reply(res, 400, { error: "İstek metni boş." });
    if (prompt.length > 150_000) return reply(res, 413, { error: "İstek metni çok uzun." });

    const endpoint = new URL(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`);
    endpoint.searchParams.set("key", apiKey);
    const upstream = await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      signal: AbortSignal.timeout(90_000),
    });
    const payload = await upstream.json().catch(() => ({}));
    if (!upstream.ok) {
      const message = payload?.error?.message ?? `Gemini isteği başarısız oldu (${upstream.status}).`;
      return reply(res, upstream.status === 429 ? 429 : 502, { error: message });
    }
    const text = payload?.candidates?.[0]?.content?.parts?.map((part) => part.text ?? "").join("").trim();
    if (!text) return reply(res, 502, { error: "Gemini boş yanıt döndürdü." });
    return reply(res, 200, { text });
  } catch (error) {
    const message = error?.name === "TimeoutError" ? "AI isteği zaman aşımına uğradı." : "İstek işlenemedi. Metni kontrol edip tekrar dene.";
    return reply(res, 500, { error: message });
  }
});

server.listen(port, host, () => console.log(`StudyFlow AI proxy listening at http://${host}:${port}`));
