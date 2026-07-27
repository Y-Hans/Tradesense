# Open Integration Requests

This directory stores active, unresolved cross-developer integration requests.

## File Naming Convention
```text
<sender>-to-<recipient>-<short-description>.md
```
Example: `laksh-to-divyanshu-binance-ws-feed.md`

## Request Format
Each open request file should use the standard template:

```markdown
# <Sender>'s Request to <Recipient>

Status:
OPEN

Priority:
BLOCKING / NON-BLOCKING

## What is needed

[Detailed description of contract or provider change required]

## Why

[Rationale and feature requirement driving the request]

## Relevant Context

[Affected files, error logs, or design context]

## Expected Behaviour

[Clear description of the expected output/behavior after change]

## Ownership Boundary

Sender should not modify:
- [Recipient's owned files]

Recipient should not modify:
- [Sender's owned files]

## Resolution

Pending
```
