# Cross-Developer Integration Request Protocol

Managed by: `Yajat` (Integration Lead)

This document defines the official process for managing cross-developer changes and integration requests across parallel feature branches.

---

## Directory Index
- Open Requests: [`docs/integration-requests/open/`](file:///c:/Users/user/shpathon/docs/integration-requests/open/)
- Resolved Requests: [`docs/integration-requests/resolved/`](file:///c:/Users/user/shpathon/docs/integration-requests/resolved/)

---

## Cross-Developer Request Lifecycle

When Developer A discovers they need a change in Developer B's owned area or shared contract:

1. **Do NOT Modify Foreign Files**: Developer A must **NOT** edit Developer B's files directly or alter shared contracts independently.
2. **Request Generation**: Developer A's planning agent offers to generate an integration request document:
   `docs/integration-requests/open/A-to-B-<short-description>.md`
3. **Request Review**: Developer B's planning agent reviews the request.
4. **Acceptance & Scope Inclusion**: If accepted, Developer B's task prompt includes creating/updating the request document under `docs/integration-requests/open/`.
5. **Isolated Implementation**: Developer B implements only B-owned work.
6. **Focused Commit**: Developer B delivers the isolated change preferably as a focused, standalone Git commit.
7. **Integration & Verification**: Developer A pulls/cherry-picks the commit and verifies that the change satisfies requirements.
8. **Resolution**: Once verified, Developer A's agent updates the request status to `RESOLVED` and moves the file to `docs/integration-requests/resolved/`.

---

## Standard Integration Request Format

```markdown
# <Sender>'s Request to <Recipient>

Status:
OPEN

Priority:
BLOCKING / NON-BLOCKING

## What is needed

...

## Why

...

## Relevant Context

...

## Expected Behaviour

...

## Ownership Boundary

Sender should not modify:
...

Recipient should not modify:
...

## Resolution

Pending
```

---

## Branch / Cherry-Pick Rule

Developers work primarily on separate feature branches. A full repository merge is **NOT** required every time one developer needs another developer's isolated change.

For isolated requested work:
1. Developer B creates a focused standalone commit on their branch.
2. Developer A fetches and cherry-picks the specific commit:
   ```bash
   git fetch origin
   git cherry-pick <commit-hash>
   ```

### ⚠️ Cherry-Pick Safety Rule:
A commit must **NOT** be recommended for isolated cherry-picking unless it is strictly self-contained relative to the requester's baseline.
If the requested commit depends on earlier unmerged commits:
- Either identify the required commit chain/order explicitly, or
- Route the integration through `Yajat` (Integration Lead) for coordinated baseline integration.

Changes to **shared contracts or architecture** must go through the Integration Lead rather than being independently cherry-picked across branches.
