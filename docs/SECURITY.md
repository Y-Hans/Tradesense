# Security Best Practices

## 1. Secrets Management
- **OpenRouter API Keys**: Must NEVER be committed to Git or embedded in the Flutter application bundle. They reside strictly in Supabase Edge Function environment secrets.
- **RevenueCat Webhook Secrets**: Reside strictly in server environment variables.
- **Supabase Service-Role Keys**: Reside strictly on the server side.

## 2. Row Level Security (RLS)
Every table in Supabase PostgreSQL has RLS enabled with `auth.uid() = user_id` policies to prevent unauthorized user cross-reads.

## 3. Rate Limiting
Supabase Edge Functions implement per-user rate limiting (e.g. max 10 AI Coach calls per hour) to prevent API abuse.
