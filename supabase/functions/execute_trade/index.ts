import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
const ACCOUNT_CURRENCY = "INR";
const QUOTE_PRIORITY = ["INR", "USDT", "USDC", "USD"];
type ExchangeSymbol = { symbol?: string; baseAsset?: string; quoteAsset?: string; status?: string };

class PricingError extends Error {
  constructor(public code: string, message: string, public status = 503) { super(message); }
}
function json(data: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}
function finitePositive(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value > 0;
}
function normalizeAsset(value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new PricingError("INVALID_ASSET", "Asset symbol is required.", 400);
  const raw = value.trim().toUpperCase();
  for (const quote of ["USDT", "USDC", "INR", "USD"]) if (raw.endsWith(quote) && raw.length > quote.length) return raw.slice(0, -quote.length);
  return raw;
}
async function fetchJson(url: string, timeoutMs: number, unavailableCode = "UPSTREAM_UNAVAILABLE"): Promise<any> {
  let response: Response;
  try { response = await fetch(url, { signal: AbortSignal.timeout(timeoutMs) }); }
  catch (_) { throw new PricingError(unavailableCode, "Required pricing provider is unavailable."); }
  if (!response.ok) throw new PricingError(unavailableCode, `Pricing provider returned HTTP ${response.status}.`);
  try { return await response.json(); }
  catch (_) { throw new PricingError("MALFORMED_UPSTREAM_RESPONSE", "Pricing provider returned malformed JSON."); }
}
async function resolvePair(asset: string): Promise<ExchangeSymbol> {
  const metadata = await fetchJson("https://api.binance.com/api/v3/exchangeInfo", 5000);
  if (!Array.isArray(metadata?.symbols)) throw new PricingError("MALFORMED_UPSTREAM_RESPONSE", "Exchange metadata was malformed.");
  const candidates = (metadata.symbols as ExchangeSymbol[]).filter((item) => item.baseAsset === asset && item.status === "TRADING" && typeof item.symbol === "string" && typeof item.quoteAsset === "string" && QUOTE_PRIORITY.includes(item.quoteAsset));
  for (const quote of QUOTE_PRIORITY) { const match = candidates.find((item) => item.quoteAsset === quote); if (match) return match; }
  throw new PricingError("NO_SUPPORTED_MARKET_PAIR", `No supported live market pair exists for ${asset}.`, 400);
}
async function fetchNativePrice(pair: ExchangeSymbol) {
  const data = await fetchJson(`https://api.binance.com/api/v3/ticker/price?symbol=${encodeURIComponent(pair.symbol!)}`, 5000);
  const price = typeof data?.price === "string" ? Number(data.price) : data?.price;
  if (!finitePositive(price)) throw new PricingError("INVALID_MARKET_PRICE", "Exchange returned an invalid market price.");
  return { price, timestamp: new Date().toISOString() };
}
async function fetchFxRate(fromCurrency: string) {
  if (fromCurrency === ACCOUNT_CURRENCY) return { rate: 1, source: "identity", timestamp: new Date().toISOString() };
  if (fromCurrency === "USDT") {
    const data = await fetchJson("https://api.coingecko.com/api/v3/simple/price?ids=tether&vs_currencies=inr", 3000, "FX_UNAVAILABLE");
    const rate = data?.tether?.inr;
    if (!finitePositive(rate)) throw new PricingError("FX_UNAVAILABLE", "Live USDT/INR rate is unavailable.");
    return { rate, source: "CoinGecko:tether/INR", timestamp: new Date().toISOString() };
  }
  if (fromCurrency === "USDC") {
    const data = await fetchJson("https://api.coingecko.com/api/v3/simple/price?ids=usd-coin&vs_currencies=inr", 3000, "FX_UNAVAILABLE");
    const rate = data?.["usd-coin"]?.inr;
    if (!finitePositive(rate)) throw new PricingError("FX_UNAVAILABLE", "Live USDC/INR rate is unavailable.");
    return { rate, source: "CoinGecko:usd-coin/INR", timestamp: new Date().toISOString() };
  }
  if (fromCurrency === "USD") {
    const data = await fetchJson("https://api.frankfurter.app/latest?from=USD&to=INR", 3000, "FX_UNAVAILABLE");
    const rate = data?.rates?.INR;
    if (!finitePositive(rate)) throw new PricingError("FX_UNAVAILABLE", "Live USD/INR rate is unavailable.");
    return { rate, source: "Frankfurter:USD/INR", timestamp: new Date().toISOString() };
  }
  throw new PricingError("FX_UNSUPPORTED", `No live FX provider supports ${fromCurrency}/INR.`, 400);
}
async function authoritativePrice(asset: string) {
  const pair = await resolvePair(asset);
  const native = await fetchNativePrice(pair);
  const fx = await fetchFxRate(pair.quoteAsset!);
  const priceInr = native.price * fx.rate;
  if (!finitePositive(priceInr)) throw new PricingError("INVALID_INR_PRICE", "Calculated INR price is invalid.");
  return { pair, native, fx, priceInr, calculatedAt: new Date().toISOString() };
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing Authorization header" }, 401);
    const client = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_ANON_KEY") ?? "", { global: { headers: { Authorization: authHeader } } });
    const { data: { user }, error: userError } = await client.auth.getUser();
    if (userError || !user) return json({ error: "Unauthorized" }, 401);
    const body = await req.json().catch(() => null);
    if (!body) return json({ error: "Invalid request body" }, 400);
    const { quantity, side, client_order_id, stop_loss_price_inr } = body;
    const asset = normalizeAsset(body.symbol);
    if (!finitePositive(quantity)) return json({ error: "Quantity must be a finite positive number" }, 400);
    if (side !== "buy" && side !== "sell") return json({ error: "Side must be buy or sell" }, 400);
    if (typeof client_order_id !== "string" || client_order_id.length === 0) return json({ error: "client_order_id is required" }, 400);
    if (stop_loss_price_inr != null && !finitePositive(stop_loss_price_inr)) return json({ error: "Stop-loss price must be a finite positive number" }, 400);
    const pricing = await authoritativePrice(asset);
    if (side === "buy" && stop_loss_price_inr != null && stop_loss_price_inr >= pricing.priceInr) return json({ error: "Buy stop-loss must be below the authoritative execution price" }, 400);
    const serviceClient = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");
    const rpcName = side === "buy" ? "execute_buy_order" : "execute_sell_order";
    // The RPC stores the canonical base asset. The exact exchange pair and
    // quote are returned as pricing metadata and are never confused with the
    // account/holding symbol.
    const rpcParams = { p_user_id: user.id, p_symbol: asset, p_quantity: quantity, p_execution_price_inr: pricing.priceInr, p_client_order_id: client_order_id, ...(side === "buy" ? { p_stop_loss_price_inr: stop_loss_price_inr ?? null } : {}) };
    const { data: tradeId, error: rpcError } = await serviceClient.rpc(rpcName, rpcParams);
    if (rpcError) {
      if (rpcError.code === "23505" || rpcError.message.includes("unique")) {
        const { data: existing } = await serviceClient.from("trades").select("id, execution_price_inr").eq("client_order_id", client_order_id).eq("user_id", user.id).maybeSingle();
        if (existing) return json({ trade_id: existing.id, execution_price_inr: existing.execution_price_inr, idempotent: true });
      }
      return json({ error: rpcError.message }, 400);
    }
    return json({ trade_id: tradeId, execution_price_inr: pricing.priceInr, pricing: { asset_symbol: asset, exchange_symbol: pricing.pair.symbol, base_currency: pricing.pair.baseAsset, quote_currency: pricing.pair.quoteAsset, market_source: "Binance", market_timestamp: pricing.native.timestamp, native_price: pricing.native.price, fx_source: pricing.fx.source, fx_timestamp: pricing.fx.timestamp, calculated_inr_timestamp: pricing.calculatedAt } });
  } catch (error) {
    if (error instanceof PricingError) return json({ error: error.message, code: error.code }, error.status);
    console.error("Trade execution error", error);
    return json({ error: "Internal trade execution error" }, 500);
  }
});
