# Environment Configuration — dart-define Template
#
# Managed by: Divyanshu (Platform Lead)
# Security:   This file documents the SHAPE of required build-time defines.
#             NEVER commit a file containing real secrets to this repository.
#
# ------------------------------------------------------------------------------
# How to use
# ------------------------------------------------------------------------------
#
# Option A — pass defines inline (recommended for CI):
#
#   flutter run \
#     --dart-define=APP_ENV=development \
#     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
#     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
#     --dart-define=REVENUECAT_PUBLIC_KEY=goog_xxxxxxxxxxxxxxxxxxxx
#
# Option B — use a dart-defines JSON file (VS Code / Android Studio launch.json):
#
#   flutter run --dart-define-from-file=.dart_defines.json
#
#   Where .dart_defines.json (gitignored) contains:
#   {
#     "APP_ENV": "development",
#     "SUPABASE_URL": "https://your-project.supabase.co",
#     "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#     "REVENUECAT_PUBLIC_KEY": "goog_xxxxxxxxxxxxxxxxxxxx"
#   }
#
# ------------------------------------------------------------------------------
# Required defines
# ------------------------------------------------------------------------------
#
# APP_ENV              — one of: development | staging | production
#                        Default when omitted: development
#
# SUPABASE_URL         — Supabase project URL
#                        Found in: Supabase Dashboard → Settings → API → URL
#
# SUPABASE_ANON_KEY    — Supabase public anonymous JWT
#                        Found in: Supabase Dashboard → Settings → API → anon key
#                        Safe for client inclusion; Row Level Security enforces access.
#
# REVENUECAT_PUBLIC_KEY — RevenueCat public SDK key (Google Play variant)
#                         Found in: RevenueCat Dashboard → Project → API Keys → Public
#                         Typically starts with: goog_
#
# ------------------------------------------------------------------------------
# Future defines (reserved — not yet consumed)
# ------------------------------------------------------------------------------
#
# FIREBASE_PROJECT_ID  — Firebase project identifier (future Firebase integration)
# BINANCE_WS_BASE_URL  — Override for Binance WebSocket base URL (testing/proxy)
# COINGECKO_BASE_URL   — Override for CoinGecko REST base URL (testing/proxy)
#
# ------------------------------------------------------------------------------
# Security contract
# ------------------------------------------------------------------------------
#
# The following MUST NEVER appear as dart-define values:
#   - Supabase service_role key
#   - OpenRouter API key
#   - RevenueCat server secret
#   - Any private key or server-side credential
#
# These belong in Supabase Secrets Manager / GitHub Actions secrets ONLY.
