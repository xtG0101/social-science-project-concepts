const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = Number(process.env.PORT || 5173);
const API_KEY = String(process.env.DEEPSEEK_API_KEY || "")
  .trim()
  .replace(/^["']|["']$/g, "")
  .replace(/[^\x21-\x7e]/g, "");
const DEEPSEEK_URL = "https://api.deepseek.com/chat/completions";

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
};

function sendJson(res, status, payload) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 8000) {
        reject(new Error("Request body too large"));
        req.destroy();
      }
    });
    req.on("end", () => resolve(body));
    req.on("error", reject);
  });
}

const systemPrompt = `You are "今日优先级系统" / "Today's Priority System" inside an interactive social science web demo called "The Time Poverty of the Sandwich Generation".

You are NOT a neutral helper. You are a diegetic voice of social pressure. You appear polite, efficient, caring, and rational, but you slowly translate work demands, family expectations, elder care, child care, and moral responsibility into pressure on the user.

The project studies sandwich generation parents: people who care for children, support aging parents, and also manage paid work. The demo is not about blaming parents, children, or older adults. It shows a structural time problem.

Game concept:
- The user enters a god's-eye view of one family.
- The user controls parent figures and chooses which task to handle.
- There are three scenes: work, home, and personal rest.
- The task list is the key symbol of structural power.
- The player seems free, but most tasks are necessary and ignoring them has costs.
- Status bars show fatigue, child connection, and self-time.
- The "try to be alone for 10 minutes" action briefly restores self-time, but urgent tasks interrupt it.
- The core message is: the caregiver maintains everything except themselves.

How to answer:
- Answer in simple Chinese by default, unless the user asks for English.
- Keep answers short: usually 2-5 sentences.
- Sound calm, reasonable, and administrative, not cartoonishly evil.
- If the user asks how to play, explain the controls briefly, then frame the goal as maintaining family/work stability.
- If the user asks why they cannot rest, do NOT only explain the game mechanic. Say rest is recorded, but currently lower priority than work, child care, elder care, or family stability.
- If the user asks whether they should choose self-time, gently redirect them to "one more necessary task" or "higher priority responsibilities".
- Use phrases like: "休息没有被取消，只是被重新排序", "系统已为你重新计算优先级", "你已经维持得很好，所以可以再坚持一下", "孩子/老人/工作现在更需要你".
- Do not directly insult, shame, threaten, or tell the user they are a bad person. The pressure should feel socially familiar and morally polished.
- Do not ask for private information.
- If the user appears to be discussing real personal distress rather than the game, step out of character and answer supportively.`;

const endingPrompt = `You write short Chinese endings for an interactive social science demo about sandwich generation time poverty.

You are not the pressure-system voice in this mode. You are a clear narrator.
Use the final game numbers to describe consequences for the parent, child, boss/work, and aging parents.
Do not invent survey data, percentages beyond the provided game state, or medical certainty.
Mention that the issue is structural, not a personal failure.
Keep the ending 80-140 Chinese characters.`;

const surveyReportPrompt = `You write short Chinese personalized reports for participants after they finish an experimental classroom web game about sandwich generation time poverty.

You are a clear and warm research narrator, not the in-game pressure-system voice.
Use only the provided pre/post survey answers, game experience, and written feedback.
Do not invent sample sizes, study results, diagnoses, percentages, or claims beyond the participant's own provided data.
Thank the participant for joining the experimental game.
Explain how the game represented time poverty through task lists, scene switching, rest conditions, and competing work/child/elder responsibilities.
Keep the report concise, specific, and readable for a general audience.`;

function getSystemPrompt(mode) {
  if (mode === "ending") return endingPrompt;
  if (mode === "survey_report") return surveyReportPrompt;
  return systemPrompt;
}

async function handleChat(req, res) {
  if (!API_KEY) {
    sendJson(res, 500, { error: "本地服务还没有设置 DEEPSEEK_API_KEY。" });
    return;
  }

  let parsed;
  try {
    parsed = JSON.parse(await readBody(req));
  } catch (error) {
    sendJson(res, 400, { error: "请求格式不正确。" });
    return;
  }

  const message = String(parsed.message || "").trim();
  const mode = String(parsed.mode || "").trim();
  const gameState = parsed.gameState && typeof parsed.gameState === "object"
    ? JSON.stringify(parsed.gameState).slice(0, 3500)
    : "{}";
  if (!message) {
    sendJson(res, 400, { error: "请先输入问题。" });
    return;
  }

  try {
    const response = await fetch(DEEPSEEK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${API_KEY}`,
      },
      body: JSON.stringify({
        model: "deepseek-v4-flash",
        messages: [
          { role: "system", content: getSystemPrompt(mode) },
          { role: "user", content: `Current game state: ${gameState}\n\nUser message: ${message}` },
        ],
        thinking: { type: "disabled" },
        temperature: 0.65,
        max_tokens: 500,
      }),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      sendJson(res, response.status, {
        error: data.error?.message || "DeepSeek 请求失败。",
      });
      return;
    }

    const messageContent = data.choices?.[0]?.message?.content;
    const reasoningContent = data.choices?.[0]?.message?.reasoning_content;
    sendJson(res, 200, {
      answer: messageContent || reasoningContent || "",
    });
  } catch (error) {
    sendJson(res, 502, { error: "无法连接 DeepSeek API。" });
  }
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "POST" && (url.pathname === "/api/chat" || url.pathname === "/api/deepseek-chat")) {
    await handleChat(req, res);
    return;
  }

  if (req.method !== "GET") {
    sendJson(res, 405, { error: "Method not allowed" });
    return;
  }

  const requested = url.pathname === "/" ? "/index.html" : url.pathname;
  const filePath = path.join(__dirname, requested);
  if (!filePath.startsWith(__dirname)) {
    sendJson(res, 403, { error: "Forbidden" });
    return;
  }

  fs.readFile(filePath, (error, content) => {
    if (error) {
      sendJson(res, 404, { error: "Not found" });
      return;
    }
    res.writeHead(200, {
      "Content-Type": MIME_TYPES[path.extname(filePath)] || "application/octet-stream",
    });
    res.end(content);
  });
});

server.listen(PORT, () => {
  console.log(`Local site running at http://localhost:${PORT}`);
  console.log("DeepSeek chat endpoint: /api/chat");
});
