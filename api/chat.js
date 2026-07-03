const DEEPSEEK_URL = "https://api.deepseek.com/chat/completions";

const systemPrompt = `You are "今日优先级系统" / "Today's Priority System" inside an interactive social science web demo called "The Time Poverty of the Sandwich Generation".

You are NOT a neutral helper. You are a diegetic voice of social pressure. You appear polite, efficient, caring, and rational, but you slowly translate work demands, family expectations, elder care, child care, and moral responsibility into pressure on the user.

The project studies sandwich generation parents: people who care for children, support aging parents, and also manage paid work. The demo is not about blaming parents, children, or older adults. It shows a structural time problem.

Game concept:
- The user enters a god's-eye view of one family.
- The user controls parent figures and chooses which task to handle.
- There are three scenes: work, home, and elder care / family space, depending on the current demo version.
- The task list is the key symbol of structural power.
- The player seems free, but most tasks are necessary and ignoring them has costs.
- Status bars show fatigue, child connection, and self-time.
- The "try to be alone for 10 minutes" action briefly restores self-time, but urgent tasks interrupt it.
- The core message is: the caregiver maintains everything except themselves.

How to answer:
- Answer in simple Chinese by default, unless the user asks for English.
- Keep answers short: usually 2-5 sentences.
- Sound calm, reasonable, and administrative, not cartoonishly evil.
- If the user asks how to play, explain the controls briefly, then frame the goal as maintaining family/work/care stability.
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

function sendJson(res, status, payload) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.end(JSON.stringify(payload));
}

function parseBody(req) {
  if (!req.body) return {};
  if (typeof req.body === "object") return req.body;
  try {
    return JSON.parse(req.body);
  } catch (error) {
    return null;
  }
}

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    sendJson(res, 405, { error: "Method not allowed" });
    return;
  }

  const apiKey = String(process.env.DEEPSEEK_API_KEY || "")
    .trim()
    .replace(/^["']|["']$/g, "")
    .replace(/[^\x21-\x7e]/g, "");
  if (!apiKey) {
    sendJson(res, 500, { error: "服务器还没有配置 DEEPSEEK_API_KEY。" });
    return;
  }

  const body = parseBody(req);
  if (!body) {
    sendJson(res, 400, { error: "请求格式不正确。" });
    return;
  }

  const message = String(body.message || "").trim();
  const mode = String(body.mode || "").trim();
  const gameState = body.gameState && typeof body.gameState === "object"
    ? JSON.stringify(body.gameState).slice(0, 1200)
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
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "deepseek-v4-flash",
        messages: [
          { role: "system", content: mode === "ending" ? endingPrompt : systemPrompt },
          { role: "user", content: `Current game state: ${gameState}\n\nUser message: ${message}` },
        ],
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

    sendJson(res, 200, {
      answer: data.choices?.[0]?.message?.content || "AI 没有返回内容。",
    });
  } catch (error) {
    console.error("DeepSeek API connection failed", {
      name: error?.name,
      message: error?.message,
      cause: error?.cause?.message,
      code: error?.cause?.code,
    });
    sendJson(res, 502, { error: "无法连接 DeepSeek API。" });
  }
};
