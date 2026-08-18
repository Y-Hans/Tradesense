import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const rateLimitMap = new Map<string, number>();

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Authenticate user
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const now = Date.now();
    const lastCall = rateLimitMap.get(user.id);
    if (lastCall && now - lastCall < 5000) { // 5 seconds limit
      return new Response(JSON.stringify({ error: 'Rate limit exceeded. Please wait.' }), {
        status: 429,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    rateLimitMap.set(user.id, now);

    const body = await req.json();
    const { trade_id, trade_details, discipline_score, risk_score } = body;

    if (!trade_id || !trade_details) {
      return new Response(JSON.stringify({ error: 'Missing trade information' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Call OpenRouter
    const openRouterKey = Deno.env.get('OPENROUTER_API_KEY');
    if (!openRouterKey) {
      throw new Error('OPENROUTER_API_KEY is not configured on the server');
    }

    const systemPrompt = `You are an expert AI trading coach. Analyze the user's trade and provide constructive feedback in JSON format.
Your feedback MUST be a valid JSON object with the following exact keys:
- what_done_well (string)
- what_increased_risk (string)
- what_to_learn (string)
- what_to_consider_next (string)
`;

    const userPrompt = `Analyze this trade:
Trade: ${JSON.stringify(trade_details)}
Discipline Score: ${JSON.stringify(discipline_score)}
Risk Score: ${JSON.stringify(risk_score)}
`;

    const start = Date.now();
    const orResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3-haiku', // Fast and cheap model for analysis
        response_format: { type: "json_object" },
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ]
      })
    });

    if (!orResponse.ok) {
      throw new Error(`OpenRouter API error: ${orResponse.statusText}`);
    }

    const orData = await orResponse.json();
    const latency = Date.now() - start;
    const content = orData.choices[0].message.content;
    let coachResponse;
    try {
      coachResponse = JSON.parse(content);
    } catch (e) {
      console.error('Failed to parse AI response as JSON:', content);
      throw new Error('AI returned invalid JSON');
    }

    // Persist to trade_analyses table
    const analysisPayload = {
      trade_id: trade_id,
      user_id: user.id,
      discipline_score: discipline_score,
      risk_score: risk_score,
      coach_feedback: {
        ...coachResponse,
        ai_provider: 'OpenRouter',
        model_id: orData.model,
        prompt_version: '1.0',
        latency_ms: latency
      },
      analyzed_at: new Date().toISOString()
    };

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { error: insertError } = await serviceClient
      .from('trade_analyses')
      .upsert(analysisPayload);

    if (insertError) {
      console.error('Database insert error:', insertError);
      // We still return the analysis to the client, but log the error
    }

    return new Response(JSON.stringify(analysisPayload.coach_feedback), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Edge Function Error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
