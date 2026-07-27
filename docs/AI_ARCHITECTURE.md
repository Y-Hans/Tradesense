# AI Coach Architecture & Server-Side OpenRouter Integration

## 1. V1 Architecture Pipeline
```
Flutter App
 └── CoachService (AIProvider)
      └── Supabase Edge Function (ai-coach/index.ts)
           ├── Server-Side OpenRouter API Key (Secrets Manager)
           ├── OpenRouter API (Default: anthropic/claude-3.5-sonnet)
           └── Database Telemetry Logger (ai_interactions)
```

## 2. Server-Side OpenRouter Key Isolation
- The Flutter app **NEVER** stores or transmits the OpenRouter API key.
- The model ID is server-configurable (`AI_COACH_MODEL_ID` env var in Deno), allowing instant model upgrades without rebuilding Android AAB packages.

## 3. Future Model Data Foundation (Ethical Telemetry)
All user interactions log structured telemetry to `ai_interactions` in Supabase:
- Trade Context (symbol, side, amount, stop-loss presence)
- Portfolio Context (equity, concentration)
- Risk Score & Discipline Score
- OpenRouter prompt version & response latency
- User feedback rating (1-5 stars)

This structured dataset enables future offline model fine-tuning without continuous auto-training risk.
