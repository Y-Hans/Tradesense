# TradeSense Pricing Architecture

## Account currency

Wallets and trade accounting remain INR (`virtual_wallets.balance_inr`).

## Pair resolution

The asset symbol is separate from the exchange trading pair. Binance exchange
metadata is inspected at runtime. Supported pairs are selected in this order:

1. direct `INR`
2. `USDT`
3. `USDC`
4. `USD`

The first available `TRADING` pair is selected. Unsupported pairs are rejected;
the client does not construct pair symbols blindly.

## INR pricing

For an INR pair, the native market price is the INR price. For another quote,
the server obtains a live quote-to-INR rate and calculates:

```text
INR price = native market price × live quote/INR rate
```

There is no hardcoded FX fallback. FX failure rejects execution before the RPC
is called. Display and execution both expose pair, quote, source, timestamps,
and freshness; execution is always independently priced by the Edge Function.

## Currency conversion

The reusable Flutter converter uses the same explicit FX contract. The current
TradeSense conversion fee is zero because no pre-existing fee configuration was
found. The UI displays `Conversion fee: 0%` and does not deduct an invented fee.

## Verification status

- Source inspection: VERIFIED for removal of the production `83.5` fallback.
- Static migration script: VERIFIED for the current SQL text only.
- Flutter analyzer/tests: NOT VERIFIED in the current environment; Dart/Flutter
  commands did not return output.
- Local Supabase reset and real concurrency/RLS tests: NOT VERIFIED because the
  Docker Linux daemon is unavailable.
