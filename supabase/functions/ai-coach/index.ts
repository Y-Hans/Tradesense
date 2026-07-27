import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY");
const DEFAULT_MODEL_ID = Deno.env.get("AI_COACH_MODEL_ID") || "anthropic/claude-3.5-sonnet";
const PROMPT_VERSION = "v1.0.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    const { userId, tradeId, tradeContext, portfolioContext, riskScore, disciplineScore } = await req.json();

    if (!OPENROUTER_API_KEY) {
      throw new Error("OPENROUTER_API_KEY is not configured on server.");
    }

    const systemPrompt = `You are the AI Trading Coach in a Gamified Crypto Trading Education Simulator.
Your primary educational philosophy is: "Profit does not necessarily mean you made a good decision."
Explain trade execution in terms of process, risk management, position sizing, and stop-loss discipline.
DO NOT recalculate portfolio balances or scores. Use the provided metrics.
Return strict JSON with keys: what_done_well, what_increased_risk, what_to_learn, what_to_consider_next.`;

    const userPrompt = `Trade Context: ${JSON.stringify(tradeContext)}
Portfolio Context: ${JSON.stringify(portfolioContext)}
Calculated Risk Score: ${riskScore}/100
Calculated Discipline Score: ${disciplineScore}/100`;

    const openRouterResponse = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "HTTP-Referer": "https://cryptoedu.app",
        "X-Title": "CryptoEdu AI Coach",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: DEFAULT_MODEL_ID,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        response_format: { type: "json_object" }
      }),
    });

    const aiResult = await openRouterResponse.json();
    const latencyMs = Date.now() - startTime;
    const coachContent = JSON.parse(aiResult.choices[0].message.content);

    const responsePayload = {
      what_done_well: coachContent.what_done_well,
      what_increased_risk: coachContent.what_increased_risk,
      what_to_learn: coachContent.what_to_learn,
      what_to_consider_next: coachContent.what_to_consider_next,
      ai_provider: "OpenRouter",
      model_id: DEFAULT_MODEL_ID,
      prompt_version: PROMPT_VERSION,
      latency_ms: latencyMs,
    };

    return new Response(JSON.stringify(responsePayload), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
