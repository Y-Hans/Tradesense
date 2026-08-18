# Historical test recovery

The previous OpenRouter client tests were deleted when Coach execution moved
behind the authenticated `coach_chat` Edge Function. Their intent is retained
by the current server-boundary tests in
`test/unit/coach/coach_repository_test.dart`, which verify:

- successful server response mapping and conversation tracking;
- no client-supplied history in the function request;
- 429, 403, and generic upstream error mapping; and
- bounded local display history.

The old provider, DTO, prompt-builder, and provider-wiring tests are not
restored with obsolete OpenRouter client classes or credentials. Their
provider-specific responsibilities now belong to the Edge Function and must
be verified with a real Supabase/Edge environment; that verification is
reported separately rather than simulated as a client test.

The deleted learning progression suite covered deterministic XP, level/title,
mission idempotency, notifier state, and domain-event integration. The current
equivalent coverage is split across:

- `test/unit/learning/learning_progression_notifier_test.dart` for state and
  backend-restored progression values;
- `test/unit/learning/learning_progression_engine_test.dart` for pure
  `LevelEngine`, `MissionEngine`, and `XpEngine` invariants; and
- backend idempotency tests, where persistence behavior is involved.

No historical test was deleted during this corrective pass. The original
deletions remain documented in Git status and this note so they are not
mistaken for passing coverage.
